#!/usr/bin/env ruby

require 'optparse'
require 'yaml'
require 'json'
require 'fileutils'
require 'openssl'
require 'base64'

def load_yaml_json!(file, type)
  if not file
    return {}
  end
  begin
    if type == "yaml"
	    hash_content = YAML.safe_load(File.open(file))
    elsif type == "json"
	    hash_content = JSON.load(File.open(file))
    end
  rescue Errno::ENOENT => e
    puts "failed to open file #{file} | #{e}"
    raise
  rescue JSON::ParserError, Psych::SyntaxError => e
    puts "failed to parse file #{file} | #{e}"
    raise
  end
  if not hash_content
    return {}
  end
  if not hash_content.is_a?(Hash)
    puts hash_content
    puts hash_content.class
    raise Psych::SyntaxError("input is expected Hash format")
  end
  return hash_content
end

def merge_hash!(hash1, hash2)
  if not hash1 and not hash2
    return {}
  elsif hash1 and not hash2
    return hash1
  elsif not hash1 and hash2
    return hash2
  else
    return hash2.merge(hash1)
  end
end

# eg. sort_info = 'k1:v1, k2:v2, ...'
def get_sort_paras!(sort_info)
  if not sort_info
    return nil
  end
  sort_paras = []
  sort_info.sub(/[\'\"]/, '')
  sort_info_list = sort_info.strip.split(/ *, */)
  sort_info_list.each do |sort_info_item|
    k, v = sort_info_item.split(':', 2)
    if k.nil? or v.nil?
      puts "sort parameter error"
      exit
    end
    sort_paras.append({k.strip => {"order" => v.strip}})
  end
  return sort_paras
end

#eg. list_info = 'v1, v2, ...'
def get_list_paras!(list_info)
  if not list_info
    return nil
  end
  list_paras = []
  list_info.gsub(/[\'\"]/, '')
  list_info_list = list_info.strip.split(/ *, */)
  list_info_list.each do |list_info_item|
    list_paras.append(list_info_item.strip)
  end
  return list_paras
end

def get_no_option_paras!(argv_array, json_path=nil, yaml_path=nil)
  if json_path
    json_hash = load_yaml_json!(json_path, "json")
  end
  if yaml_path
    yaml_hash = load_yaml_json!(yaml_path, "yaml")
  end
  hash_paras = merge_hash!(json_hash, yaml_hash) # prior json > yaml
  array_paras = []
  ARGV.each do |arg|
    if arg.include?('=')
      if arg.match?(/package_overrides.*.lock=/)
        tmp_list = arg.split(/\.|=/)
        nested_hash = tmp_list.pop.downcase
        nested_hash = true if nested_hash == "true"
        nested_hash = false if nested_hash == "false"
        reverse_list = tmp_list.reverse!
        reverse_list.each do |ele|
          nested_hash = { ele => nested_hash }
        end
      else
        k, v = arg.split('=', 2)
        v = true if v == "true"
        v = false if v == "false"
        hash_paras[k.strip] = v # prior k=v > json > yaml
      end
      hash_paras = merge_hash!(nested_hash, hash_paras)
    else
      array_paras.append(arg)
    end
  end
  return hash_paras, array_paras
end

def load_my_config
  config = {}
  self_config_path = "#{ENV['HOME']}/.config/cli"
  Dir.glob(['/etc/cli/defaults/*.yaml',
            "#{self_config_path}/defaults/*.yaml"]).each do |file|
    config.merge! load_yaml_json!(file, 'yaml')
  end
  if not config.has_key?('GATEWAY_IP') or not config.has_key?('GATEWAY_PORT')
    puts 'gatway config not found'
    exit
  end
  return config
end

def encrypt_password(password, public_key_url)
  response_str = %x(curl -s "#{public_key_url}")
  public_key_string = JSON.parse(response_str)['data']['rsa']['publicKey']

  rsa = OpenSSL::PKey::RSA.new public_key_string
  Base64.encode64(rsa.public_encrypt password).gsub!("\n", '')
end

def load_jwt?(force_update=false)
  begin
    local_jwt = File.read("#{ENV['HOME']}/.config/cli/jwt")
  rescue Errno::ENOENT => e
    local_jwt = nil
  end
  if local_jwt.nil? or force_update
    config = load_my_config
    jwt = get_jwt_from_remote(config['ENABLE_AUTH_CODE'], config)
    if jwt.nil?
      api_client = CcbApiClient.new(config['GATEWAY_IP'], config['GATEWAY_PORT'])
      response = api_client.get_remote_status
      response = JSON.parse(response)
      remote_status = response['enable_auth_code_api']
      if remote_status != config['ENABLE_AUTH_CODE']
        jwt = get_jwt_from_remote(remote_status, config)
        puts 'get jwt failed' if jwt.nil?
      end
    end
    return jwt
  else
    return local_jwt
  end
end

def get_jwt_from_remote(status, config)
  if status
    config['MY_ACCOUNT'] ||= ENV['MY_ACCOUNT'].strip
    config['AUTH_CODE'] ||= ENV['AUTH_CODE'].strip
    request_json = {"account" => config['MY_ACCOUNT'], "auth_code" => config['AUTH_CODE']}.to_json
    api_client = CcbApiClient.new(config['GATEWAY_IP'], config['GATEWAY_PORT'])
    response = api_client.get_offline_jwt(request_json)
    response = JSON.parse(response)
    response = response['msg']
  else
    config['ACCOUNT'] ||= ENV['ACCOUNT'].strip
    config['PASSWORD'] ||= ENV['PASSWORD'].strip
    config['PUBLIC_KEY_URL'] ||= ENV['PUBLIC_KEY_URL'].strip
    password = encrypt_password(config['PASSWORD'], config['PUBLIC_KEY_URL'])
    api_client = CcbApiClient.new(config['GATEWAY_IP'], config['GATEWAY_PORT'])
    response = api_client.get_access_token(config['ACCOUNT'], password)
    body = JSON.parse(response.body)
    access_token = body['msg']['token']
  end
  if access_token
    FileUtils.mkdir_p "#{ENV['HOME']}/.config/cli" unless File.directory? "#{ENV['HOME']}/.config/cli"
    aFile = File.new("#{ENV['HOME']}/.config/cli/jwt", "w+")
    if aFile
      aFile.syswrite(access_token)
    else
      puts 'save jwt faild'
    end
    return access_token
  else
    return nil
  end
end

def check_return_code(response)
  status_code_array = [401, 403, 404]
  if response.has_key?('status_code') && status_code_array.include?(response['status_code'])
    case response['status_code']
    when 401
      puts 'Jwt has expired'
    when 403
      puts 'Please register account first'
    when 404
      puts "Url not found: #{response['url']}"
    end
    exit
  end
end
