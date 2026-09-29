# frozen_string_literal: true

require "test_helper"
require "json"
require "uri"
require "ccb_api_client"

class TestCcbApiClient < Minitest::Test
  IP_HOST = "127.0.0.1"
  PORT = 10012
  BASE = "http://127.0.0.1:10012"

  def client(host = IP_HOST, port = PORT)
    CcbApiClient.new(host, port)
  end

  # --- initialization ------------------------------------------------------

  def test_default_host_and_port
    c = CcbApiClient.new
    response = c.get_client_info
    call = rest_client.find(:get)
    assert_equal "http://172.17.0.1:10012/api/user_auth/get_client_info", call[:url]
  end

  def test_ip_address_uses_http_prefix
    c = client
    c.get_client_info
    assert_equal "#{BASE}/api/user_auth/get_client_info", rest_client.find(:get)[:url]
  end

  def test_domain_name_uses_https_prefix
    c = CcbApiClient.new("api.example.com", 443)
    c.get_client_info
    assert_equal "https://api.example.com:443/api/user_auth/get_client_info",
                 rest_client.find(:get)[:url]
  end

  # --- POST endpoints ------------------------------------------------------

  def test_search_posts_payload_with_authorization
    c = client
    rest_client.returns(rest_response(200, "results"))
    result = c.search("jwt-token", '{"q": 1}')

    call = rest_client.find(:post)
    assert_equal "#{BASE}/api/data-api/search", call[:url]
    assert_equal '{"q": 1}', call[:payload]
    assert_equal "jwt-token", call[:headers]["Authorization"]
    assert_equal :json, call[:headers][:content_type]
    assert_equal "results", result.body
  end

  def test_create_os_project_posts_to_os_endpoint
    c = client
    c.create_os_project("jwt", "my-os", "{}")

    assert_equal "#{BASE}/api/api/os/my-os", rest_client.find(:post)[:url]
  end

  def test_create_branch_project_posts_to_sub_project_endpoint
    c = client
    c.create_branch_project("jwt", "my-os", "my-sub", "{}")

    assert_equal "#{BASE}/api/api/os/my-os/sub-project/my-sub",
                 rest_client.find(:post)[:url]
  end

  def test_build_single_posts_to_build_single_endpoint
    c = client
    c.build_single("jwt", "my-os", "{}")

    assert_equal "#{BASE}/api/api/os/my-os/build_single", rest_client.find(:post)[:url]
  end

  def test_build_dag_posts_to_build_dag_endpoint
    c = client
    c.build_dag("jwt", "my-os", "{}")

    assert_equal "#{BASE}/api/api/os/my-os/build_dag", rest_client.find(:post)[:url]
  end

  def test_abort_build_posts_to_abort_build_endpoint
    c = client
    c.abort_build("jwt", "my-os", "{}")

    assert_equal "#{BASE}/api/api/os/my-os/abort_build", rest_client.find(:post)[:url]
  end

  def test_get_offline_jwt_posts_without_authorization_header
    c = client
    c.get_offline_jwt('{"account": "a"}')

    call = rest_client.find(:post)
    assert_equal "#{BASE}/api/user_auth/auth_code_authorize", call[:url]
    refute call[:headers].key?("Authorization")
  end

  # --- PUT endpoint --------------------------------------------------------

  def test_update_os_project_puts_to_os_endpoint
    c = client
    c.update_os_project("jwt", "my-os", "{}")

    call = rest_client.calls.first
    assert_equal :put, call[:method]
    assert_equal "#{BASE}/api/api/os/my-os", call[:url]
    assert_equal "jwt", call[:headers]["Authorization"]
  end

  # --- snapshot (Request.execute with timeout) -----------------------------

  def test_create_snapshot_uses_request_execute_with_600_second_timeout
    c = client
    c.create_snapshot("jwt", "my-os", "{}")

    call = rest_client.find(:post)
    assert_equal "#{BASE}/api/api/os/my-os/snapshot", call[:url]
    assert_equal 600, call[:timeout]
  end

  # --- GET resource endpoints ----------------------------------------------

  def test_get_jwt_uses_access_code_url
    c = client
    c.get_jwt("abc-123")

    assert_equal "#{BASE}/api/user_auth/access_code_authorize?access_code=abc-123",
                 rest_client.find(:get)[:url]
  end

  def test_get_remote_status_uses_api_status_url
    c = client
    c.get_remote_status

    assert_equal "#{BASE}/api/user_auth/api_status", rest_client.find(:get)[:url]
  end

  def test_get_access_token_encodes_credentials_in_query
    c = client
    c.get_access_token("alice", "p@ss word")

    url = rest_client.find(:get)[:url]
    assert url.start_with?("#{BASE}/api/user_auth/oauth_authorize?")
    query = url.split("?", 2).last
    params = URI.decode_www_form(query).to_h
    assert_equal(
      {
        "grant_type" => "password",
        "account" => "alice",
        "password" => "p@ss word"
      },
      params
    )
  end

  def test_get_access_token_uses_custom_grant_type
    c = client
    c.get_access_token("alice", "pw", "refresh_token")

    query = rest_client.find(:get)[:url].split("?", 2).last
    assert_equal "refresh_token", URI.decode_www_form(query).to_h["grant_type"]
  end

  # --- error handling ------------------------------------------------------

  def test_post_endpoint_returns_error_json_with_status_code_and_url
    c = client
    rest_client.returns(rest_error(404))
    result = c.search("jwt", "{}")

    parsed = JSON.parse(result)
    assert_equal 404, parsed["status_code"]
    assert_equal "#{BASE}/api/data-api/search", parsed["url"]
  end

  def test_put_endpoint_returns_error_json
    c = client
    rest_client.returns(rest_error(401))
    result = c.update_os_project("jwt", "my-os", "{}")

    parsed = JSON.parse(result)
    assert_equal 401, parsed["status_code"]
    assert_equal "#{BASE}/api/api/os/my-os", parsed["url"]
  end

  def test_snapshot_returns_error_json
    c = client
    rest_client.returns(rest_error(500))
    result = c.create_snapshot("jwt", "my-os", "{}")

    parsed = JSON.parse(result)
    assert_equal 500, parsed["status_code"]
    assert_equal "#{BASE}/api/api/os/my-os/snapshot", parsed["url"]
  end

  def test_get_offline_jwt_returns_error_json
    c = client
    rest_client.returns(rest_error(403))
    result = c.get_offline_jwt("{}")

    parsed = JSON.parse(result)
    assert_equal 403, parsed["status_code"]
    assert_equal "#{BASE}/api/user_auth/auth_code_authorize", parsed["url"]
  end
end
