# frozen_string_literal: true

require "minitest/autorun"

REPO_ROOT = File.expand_path("..", __dir__)
$LOAD_PATH.unshift File.expand_path("test/stubs", REPO_ROOT)
$LOAD_PATH.unshift File.expand_path("lib", REPO_ROOT)
$LOAD_PATH.unshift File.expand_path("sbin/cli", REPO_ROOT)

# Deterministic in-process stand-in for the `rest-client` gem. It records every
# request and lets a test queue return values / exceptions. This keeps the unit
# tests offline and free of the external `rest-client` dependency.
module FakeRestClient
  class FakeResponse
    attr_accessor :code, :body, :headers
    def initialize(code = 200, body = "", headers = {})
      @code = code
      @body = body
      @headers = headers
    end
  end

  class ExceptionWithResponse < StandardError
    attr_reader :response
    def initialize(response)
      @response = response
      super("HTTP #{response.code}")
    end
  end

  class Recorder
    attr_reader :calls

    def initialize
      reset
    end

    def reset
      @calls = []
      @default = nil
      @queued = []
    end

    def returns(value)
      @default = value
    end

    def enqueue(*values)
      @queued.concat(values)
    end

    def record(method, url, payload, headers, extra = {})
      @calls << { method: method, url: url, payload: payload, headers: headers }.merge(extra)
      value = @queued.shift || @default
      raise value if value.is_a?(Exception)
      value
    end

    def find(method = nil, index = 0)
      list = method ? @calls.select { |c| c[:method] == method } : @calls
      list[index]
    end
  end

  class << self
    def recorder
      @recorder ||= Recorder.new
    end

    def post(url, payload, headers = {})
      recorder.record(:post, url, payload, headers)
    end

    def put(url, payload, headers = {})
      recorder.record(:put, url, payload, headers)
    end
  end

  module Request
    def self.execute(method:, url:, payload:, headers:, timeout: nil)
      FakeRestClient.recorder.record(method, url, payload, headers, timeout: timeout)
    end
  end

  class Resource
    def initialize(url)
      @url = url
    end

    def get(headers = {})
      FakeRestClient.recorder.record(:get, @url, nil, headers)
    end
  end
end

RestClient = FakeRestClient

module RestClientTestHelper
  def rest_client
    FakeRestClient.recorder
  end

  def rest_response(code = 200, body = "")
    FakeRestClient::FakeResponse.new(code, body)
  end

  def rest_error(code, body = "")
    FakeRestClient::ExceptionWithResponse.new(rest_response(code, body))
  end

  def setup
    super
    FakeRestClient.recorder.reset

    @ut_quiet = ENV["UT_QUIET"] != "0"
    return unless @ut_quiet
    @ut_orig_stdout = $stdout
    @ut_orig_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  def teardown
    if @ut_quiet
      $stdout = @ut_orig_stdout
      $stderr = @ut_orig_stderr
    end
    super
  end
end

class Minitest::Test
  include RestClientTestHelper
end
