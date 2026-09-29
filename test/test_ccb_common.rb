# frozen_string_literal: true

require "test_helper"
require "ccb_api_client"
require "ccb_common"

class TestCcbCommon < Minitest::Test
  def setup
    super
    @orig_home = ENV["HOME"]
    @orig_argv = ARGV.dup
    @tmpdir = Dir.mktmpdir
    ENV["HOME"] = @tmpdir
  end

  def teardown
    ENV["HOME"] = @orig_home
    ARGV.replace(@orig_argv)
    FileUtils.remove_entry(@tmpdir) if @tmpdir && File.directory?(@tmpdir)
    super
  end

  def write_file(name, content)
    path = File.join(@tmpdir, name)
    File.write(path, content)
    path
  end

  # --- load_yaml_json! -----------------------------------------------------

  def test_load_yaml_json_returns_empty_hash_when_file_is_nil
    assert_equal({}, load_yaml_json!(nil, "yaml"))
    assert_equal({}, load_yaml_json!(nil, "json"))
  end

  def test_load_yaml_json_returns_empty_hash_for_empty_file
    ypath = write_file("empty.yaml", "")
    jpath = write_file("empty.json", "")

    assert_equal({}, load_yaml_json!(ypath, "yaml"))
    assert_equal({}, load_yaml_json!(jpath, "json"))
  end

  def test_load_yaml_json_reads_yaml_hash
    path = write_file("data.yaml", "a: 1\nb: two\n")
    assert_equal({ "a" => 1, "b" => "two" }, load_yaml_json!(path, "yaml"))
  end

  def test_load_yaml_json_reads_json_hash
    path = write_file("data.json", '{"a": 1, "b": "two"}')
    assert_equal({ "a" => 1, "b" => "two" }, load_yaml_json!(path, "json"))
  end

  def test_load_yaml_json_raises_on_missing_file
    assert_raises(Errno::ENOENT) do
      load_yaml_json!(File.join(@tmpdir, "absent.yaml"), "yaml")
    end
  end

  def test_load_yaml_json_raises_on_invalid_yaml_syntax
    path = write_file("bad.yaml", "a: 1\n  b: [unclosed\n")
    assert_raises(Psych::SyntaxError) do
      load_yaml_json!(path, "yaml")
    end
  end

  def test_load_yaml_json_raises_on_invalid_json_syntax
    path = write_file("bad.json", '{"a": }')
    assert_raises(JSON::ParserError) do
      load_yaml_json!(path, "json")
    end
  end

  def test_load_yaml_json_raises_when_content_is_not_a_hash
    path = write_file("arr.yaml", "- one\n- two\n")
    # On Psych 5 the source's `Psych.SyntaxError(...)` call is undefined.
    assert_raises(NoMethodError) do
      load_yaml_json!(path, "yaml")
    end
  end

  # --- merge_hash! ---------------------------------------------------------

  def test_merge_hash_returns_empty_when_both_nil
    assert_equal({}, merge_hash!(nil, nil))
  end

  def test_merge_hash_returns_first_when_second_nil
    h1 = { "a" => 1 }
    assert_same h1, merge_hash!(h1, nil)
  end

  def test_merge_hash_returns_second_when_first_nil
    h2 = { "a" => 1 }
    assert_same h2, merge_hash!(nil, h2)
  end

  def test_merge_hash_first_hash_takes_priority
    result = merge_hash!({ "a" => 1, "x" => 9 }, { "a" => 0, "b" => 2 })
    assert_equal({ "a" => 1, "b" => 2, "x" => 9 }, result)
  end

  # --- get_sort_paras! -----------------------------------------------------

  def test_get_sort_paras_returns_nil_for_nil
    assert_nil get_sort_paras!(nil)
  end

  def test_get_sort_paras_parses_key_order_pairs
    result = get_sort_paras!("name: asc, time: desc")
    assert_equal [
      { "name" => { "order" => "asc" } },
      { "time" => { "order" => "desc" } }
    ], result
  end

  def test_get_sort_paras_strips_whitespace
    result = get_sort_paras!("  name : asc  ,  time : desc ")
    assert_equal [
      { "name" => { "order" => "asc" } },
      { "time" => { "order" => "desc" } }
    ], result
  end

  def test_get_sort_paras_exits_when_pair_malformed
    assert_raises(SystemExit) { get_sort_paras!("no_colon_pair") }
  end

  # --- get_list_paras! -----------------------------------------------------

  def test_get_list_paras_returns_nil_for_nil
    assert_nil get_list_paras!(nil)
  end

  def test_get_list_paras_splits_values
    assert_equal %w[a b c], get_list_paras!("a, b, c")
  end

  def test_get_list_paras_strips_whitespace
    assert_equal %w[one two], get_list_paras!(" one ,  two ")
  end

  # --- get_no_option_paras! ------------------------------------------------

  def test_no_option_paras_maps_key_equals_value_and_booleans
    ARGV.replace(["name=hello", "enabled=true", "disabled=false", "plain-arg"])

    hash_paras, array_paras = get_no_option_paras!([])

    assert_equal "hello", hash_paras["name"]
    assert_equal true, hash_paras["enabled"]
    assert_equal false, hash_paras["disabled"]
    assert_equal ["plain-arg"], array_paras
  end

  def test_no_option_paras_loads_from_yaml_file
    ypath = write_file("base.yaml", "a: from_yaml\nkeep: me\n")
    ARGV.replace(["a=from_arg"])

    hash_paras, = get_no_option_paras!([], nil, ypath)

    assert_equal "from_arg", hash_paras["a"]
    assert_equal "me", hash_paras["keep"]
  end

  def test_no_option_paras_json_overrides_yaml
    ypath = write_file("base.yaml", "shared: yaml\n")
    jpath = write_file("base.json", '{"shared": "json"}')
    ARGV.replace([])

    hash_paras, = get_no_option_paras!([], jpath, ypath)

    assert_equal "json", hash_paras["shared"]
  end

  # --- load_my_config ------------------------------------------------------

  def test_load_my_config_reads_gateway_settings
    dir = File.join(@tmpdir, ".config/cli/defaults")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "g.yaml"), "GATEWAY_IP: 127.0.0.1\nGATEWAY_PORT: 10012\n")

    config = load_my_config
    assert_equal "127.0.0.1", config["GATEWAY_IP"]
    assert_equal 10012, config["GATEWAY_PORT"]
  end

  def test_load_my_config_exits_when_gateway_missing
    dir = File.join(@tmpdir, ".config/cli/defaults")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "g.yaml"), "OTHER: value\n")

    assert_raises(SystemExit) { load_my_config }
  end

  # --- check_return_code ---------------------------------------------------

  def test_check_return_code_does_nothing_without_status_code
    assert_nil check_return_code("body" => "ok")
  end

  def test_check_return_code_does_nothing_for_unhandled_code
    assert_nil check_return_code("status_code" => 200)
  end

  def test_check_return_code_exits_on_401
    assert_raises(SystemExit) { check_return_code("status_code" => 401) }
  end

  def test_check_return_code_exits_on_403
    assert_raises(SystemExit) { check_return_code("status_code" => 403) }
  end

  def test_check_return_code_exits_on_404
    assert_raises(SystemExit) do
      check_return_code("status_code" => 404, "url" => "http://x/missing")
    end
  end

  # --- encrypt_password ----------------------------------------------------

  def test_encrypt_password_returns_base64_without_newlines
    rsa_key = OpenSSL::PKey::RSA.new(2048)
    public_pem = rsa_key.public_key.to_pem
    payload = { "data" => { "rsa" => { "publicKey" => public_pem } } }.to_json

    # Intercept the `%x(curl ...)` backtick call issued by encrypt_password.
    define_singleton_method(:`) { |_cmd| payload }

    encrypted = encrypt_password("secret", "http://key/public_key")

    refute_match(/\n/, encrypted)
    assert_equal "secret", rsa_key.private_decrypt(Base64.decode64(encrypted))
  end

  # --- load_jwt? -----------------------------------------------------------

  def test_load_jwt_returns_local_token_without_network
    dir = File.join(@tmpdir, ".config/cli")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "jwt"), "local-jwt-token")

    assert_equal "local-jwt-token", load_jwt?
    assert_empty rest_client.calls
  end

  # --- get_jwt_from_remote (auth-code branch) ------------------------------

  def test_get_jwt_from_remote_auth_code_posts_credentials
    ENV["MY_ACCOUNT"] = "alice"
    ENV["AUTH_CODE"] = "123456"
    config = {
      "GATEWAY_IP" => "127.0.0.1",
      "GATEWAY_PORT" => 10012,
      "MY_ACCOUNT" => "alice",
      "AUTH_CODE" => "123456"
    }
    rest_client.returns('{"msg": "jwt-from-remote"}')

    token = get_jwt_from_remote(true, config)

    posted = rest_client.find(:post)
    assert_includes posted[:url], "/api/user_auth/auth_code_authorize"
    assert_equal JSON.parse(posted[:payload]),
                 { "account" => "alice", "auth_code" => "123456" }

    # Current behavior: this branch stores the result in `response`, while the
    # method's persist/return guard checks the separate `access_token` variable,
    # which is never set on this branch, so nothing is persisted and nil returns.
    assert_nil token
    refute File.exist?(File.join(@tmpdir, ".config/cli/jwt"))
  end
end
