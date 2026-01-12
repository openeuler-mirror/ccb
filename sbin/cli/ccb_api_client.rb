# frozen_string_literal: true

require 'rest-client'

# ccb api client class
class CcbApiClient
  def initialize(host = '172.17.0.1', port = 10_012)
    @host = host
    @port = port
    @url_prefix = url_prefix
  end

  def search(jwt, request_json)
    url = "#{@url_prefix}#{@host}:#{@port}/api/data-api/search"
    begin
      RestClient.post(url, request_json, { content_type: :json, accept: :json, 'Authorization' => jwt })
    rescue RestClient::ExceptionWithResponse => e
      return "{\"status_code\": #{e.response.code}, \"url\": \"#{url}\"}"
    end
  end

  def create_os_project(jwt, os_project, request_json)
    url = "#{@url_prefix}#{@host}:#{@port}/api/api/os/#{os_project}"
    begin
      RestClient.post(url, request_json, { content_type: :json, accept: :json, 'Authorization' => jwt })
    rescue RestClient::ExceptionWithResponse => e
      return "{\"status_code\": #{e.response.code}, \"url\": \"#{url}\"}"
    end
  end

  def create_branch_project(jwt, os_project, sub_project, request_json)
    url = "#{@url_prefix}#{@host}:#{@port}/api/api/os/#{os_project}/sub-project/#{sub_project}"
    begin
      RestClient.post(url, request_json, { content_type: :json, accept: :json, 'Authorization' => jwt })
    rescue RestClient::ExceptionWithResponse => e
      return "{\"status_code\": #{e.response.code}, \"url\": \"#{url}\"}"
    end
  end

  def update_os_project(jwt, os_project, request_json)
    url = "#{@url_prefix}#{@host}:#{@port}/api/api/os/#{os_project}"
    begin
      RestClient.put(url, request_json, { content_type: :json, accept: :json, 'Authorization' => jwt })
    rescue RestClient::ExceptionWithResponse => e
      return "{\"status_code\": #{e.response.code}, \"url\": \"#{url}\"}"
    end
  end

  def create_snapshot(jwt, os_project, request_json)
    url = "#{@url_prefix}#{@host}:#{@port}/api/api/os/#{os_project}/snapshot"
    begin
      RestClient::Request.execute(:method => :post, :url => url, :payload => request_json, :headers => {content_type: :json, accept: :json, 'Authorization' => jwt}, :timeout => 600)     
    rescue RestClient::ExceptionWithResponse => e
      return "{\"status_code\": #{e.response.code}, \"url\": \"#{url}\"}"
    end
  end

  def build_single(jwt, os_project, request_json)
    url = "#{@url_prefix}#{@host}:#{@port}/api/api/os/#{os_project}/build_single"
    begin
      RestClient.post(url, request_json, { content_type: :json, accept: :json, 'Authorization' => jwt })
    rescue RestClient::ExceptionWithResponse => e
      return "{\"status_code\": #{e.response.code}, \"url\": \"#{url}\"}"
    end
  end

  def build_dag(jwt, os_project, request_json)
    url = "#{@url_prefix}#{@host}:#{@port}/api/api/os/#{os_project}/build_dag"
    begin
      RestClient.post(url, request_json, { content_type: :json, accept: :json, 'Authorization' => jwt })
    rescue RestClient::ExceptionWithResponse => e
      return "{\"status_code\": #{e.response.code}, \"url\": \"#{url}\"}"
    end
  end

  def abort_build(jwt, os_project, request_json)
    url = "#{@url_prefix}#{@host}:#{@port}/api/api/os/#{os_project}/abort_build"
    begin
      RestClient.post(url, request_json, { content_type: :json, accept: :json, 'Authorization' => jwt })
    rescue RestClient::ExceptionWithResponse => e
      return "{\"status_code\": #{e.response.code}, \"url\": \"#{url}\"}"
    end
  end

  def get_jwt(access_code)
    resource = RestClient::Resource.new("#{@url_prefix}#{@host}:#{@port}/api/user_auth/access_code_authorize?access_code=#{access_code}")
    resource.get
  end

  def get_client_info
    resource = RestClient::Resource.new("#{@url_prefix}#{@host}:#{@port}/api/user_auth/get_client_info")
    resource.get
  end

  def get_remote_status
    resource = RestClient::Resource.new("#{@url_prefix}#{@host}:#{@port}/api/user_auth/api_status")
    resource.get
  end

  def get_offline_jwt(request_json)
    url = "#{@url_prefix}#{@host}:#{@port}/api/user_auth/auth_code_authorize"
    begin
      RestClient.post(url, request_json, { content_type: :json, accept: :json})
    rescue RestClient::ExceptionWithResponse => e
      return "{\"status_code\": #{e.response.code}, \"url\": \"#{url}\"}"
    end
  end

  def get_access_token(account, password, grant_type='password')
    params = {
      grant_type: grant_type,
      account: account,
      password: password
    }
    query = URI.encode_www_form(params)
    resource = RestClient::Resource.new("#{@url_prefix}#{@host}:#{@port}/api/user_auth/oauth_authorize?#{query}")
    resource.get
  end

  private def url_prefix
    @url_prefix = if @host.match('.*[a-zA-Z]+.*')
                    # Internet users should use domain name and https
                    'https://'
                  else
                    # used in intranet for now
                    'http://'
                  end
  end
end
