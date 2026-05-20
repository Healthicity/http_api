# frozen_string_literal: true

require "test_helper"

class HttpApiTest < Test::Unit::TestCase

  KLASS = Class.new do
    include HttpApi::Request
    include Singleton

    attr_accessor :default_options_value

    def get(path, options = {})
      perform_get(path, options)
    end

    def post(path, options = {})
      perform_post(path, options)
    end


    def put(path, options = {})
      perform_put(path, options)
    end

    def delete(path, options = {})
      perform_delete(path, options)
    end

    def url
      "http://example.com"
    end

    def default_options
      default_options_value || {}
    end

    def sleeps
      @sleeps ||= []
    end

    def sleep(_seconds)
      sleeps << _seconds
    end

  end

  def setup
    KLASS.instance.default_options_value = {}
    KLASS.instance.sleeps.clear
  end

  def test_get
    stub = stub_request(:get, "http://example.com/abc").
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    response = KLASS.instance.get('abc')

    assert(response.success?)
    assert_equal(200, response.code)
    assert_requested(stub, times: 1)
    remove_request_stub(stub)
  end

  def test_post
    stub = stub_request(:post, "http://example.com/abc").
            with(body: { name: "demo" }).
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    response = KLASS.instance.post('abc', name: "demo")

    assert(response.success?)
    assert_requested(stub, times: 1)
    remove_request_stub(stub)
  end

  def test_put
    stub = stub_request(:put, "http://example.com/abc").
            with(body: { name: "updated" }).
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    response = KLASS.instance.put('abc', name: "updated")

    assert(response.success?)
    assert_requested(stub, times: 1)
    remove_request_stub(stub)
  end

  def test_delete
    stub = stub_request(:delete, "http://example.com/abc").
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    response = KLASS.instance.delete('abc')

    assert(response.success?)
    assert_requested(stub, times: 1)
    remove_request_stub(stub)
  end

  def test_get_sends_options_as_query_params
    stub = stub_request(:get, "http://example.com/abc").
            with(query: { search: "term" }).
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    response = KLASS.instance.get('abc', search: "term")

    assert(response.success?)
    assert_requested(stub, times: 1)
    remove_request_stub(stub)
  end

  def test_default_options_are_merged_into_request_options
    KLASS.instance.default_options_value = { token: "default" }
    stub = stub_request(:get, "http://example.com/abc").
            with(query: { token: "default", search: "term" }).
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    response = KLASS.instance.get('abc', search: "term")

    assert(response.success?)
    assert_requested(stub, times: 1)
    remove_request_stub(stub)
  end

  def test_post_can_send_form_parameters
    stub = stub_request(:post, "http://example.com/abc").
            with(body: { name: "demo" }).
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    response = KLASS.instance.post('abc', parameter_passing_option: :form, name: "demo")

    assert(response.success?)
    assert_requested(stub, times: 1)
    remove_request_stub(stub)
  end

  def test_parameter_passing_option_is_not_sent_in_body
    stub = stub_request(:post, "http://example.com/abc").
            with { |request| !request.body.include?("parameter_passing_option") }.
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    response = KLASS.instance.post('abc', parameter_passing_option: :json, name: "demo")

    assert(response.success?)
    assert_requested(stub, times: 1)
    remove_request_stub(stub)
  end

  def test_retries_timeout_based_on_retry_count
    stub = stub_request(:get, "http://example.com/abc").
            to_timeout.
            then.
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    response = KLASS.instance.get('abc', retry_count: 1)

    assert(response.success?)
    assert_requested(stub, times: 2)
    remove_request_stub(stub)
  end

  def test_default_timeout_retry_count_retries_twice
    stub = stub_request(:get, "http://example.com/abc").
            to_timeout.
            then.
            to_timeout.
            then.
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    response = KLASS.instance.get('abc')

    assert(response.success?)
    assert_equal([1, 2], KLASS.instance.sleeps)
    assert_requested(stub, times: 3)
    remove_request_stub(stub)
  end

  def test_zero_retry_count_does_not_retry_timeout
    stub = stub_request(:get, "http://example.com/abc").to_timeout

    response = KLASS.instance.get('abc', retry_count: 0)

    assert_equal(408, response.code)
    assert_requested(stub, times: 1)
    remove_request_stub(stub)
  end

  def test_string_retry_count_is_supported_and_not_sent_as_query_param
    stub = stub_request(:get, "http://example.com/abc").
            with(query: { search: "term" }).
            to_timeout.
            then.
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    response = KLASS.instance.get('abc', "retry_count" => "1", search: "term")

    assert(response.success?)
    assert_requested(stub, times: 2)
    remove_request_stub(stub)
  end

  def test_negative_retry_count_does_not_retry_timeout
    stub = stub_request(:get, "http://example.com/abc").to_timeout

    response = KLASS.instance.get('abc', retry_count: -1)

    assert_equal(408, response.code)
    assert_requested(stub, times: 1)
    remove_request_stub(stub)
  end

  def test_timeout_response_is_logged
    calls = capture_log_calls do
      stub = stub_request(:get, "http://example.com/abc").to_timeout

      response = KLASS.instance.get('abc', retry_count: 0)

      assert_equal(408, response.code)
      remove_request_stub(stub)
    end

    assert_equal(["http://example.com", :get, "abc", {}, "TIMEOUT"], calls.last)
  end

  def test_successful_response_is_logged_with_parsed_body
    calls = capture_log_calls do
      stub = stub_request(:get, "http://example.com/abc").
              to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: { ok: true }.to_json)

      response = KLASS.instance.get('abc')

      assert(response.success?)
      remove_request_stub(stub)
    end

    assert_equal(["http://example.com", :get, "abc", {}, { "ok" => true }], calls.last)
  end

  def test_request_without_url_implementation_raises
    client = Class.new do
      include HttpApi::Request
    end.new

    assert_raise(NotImplementedError) { client.perform_get("abc") }
  end

  def test_success_response_message_parses_json
    stub = stub_request(:get, "http://example.com/abc").
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: { ok: true }.to_json)

    response = KLASS.instance.get('abc')

    assert(response.success?)
    assert_equal({ "ok" => true }, response.message)
    remove_request_stub(stub)
  end

  def test_created_response_is_successful
    stub = stub_request(:post, "http://example.com/abc").
            to_return(status: 201, headers: { 'Content-Type': "application/json" }, body: { id: 1 }.to_json)

    response = KLASS.instance.post('abc')

    assert(response.success?)
    assert_equal({ "id" => 1 }, response.message)
    remove_request_stub(stub)
  end

  def test_no_content_response_is_successful_without_message
    stub = stub_request(:delete, "http://example.com/abc").
            to_return(status: 204, body: "")

    response = KLASS.instance.delete('abc')

    assert(response.success?)
    assert_nil(response.message)
    remove_request_stub(stub)
  end

  def test_bad_request_response_is_failed_and_returns_message_field
    stub = stub_request(:get, "http://example.com/abc").
            to_return(status: 400, headers: { 'Content-Type': "application/json" }, body: { Message: "Invalid" }.to_json)

    response = KLASS.instance.get('abc')

    assert(response.failed?)
    assert_equal("Invalid", response.message)
    remove_request_stub(stub)
  end

  def test_bad_request_response_returns_body_without_message_field
    stub = stub_request(:get, "http://example.com/abc").
            to_return(status: 400, headers: { 'Content-Type': "application/json" }, body: { error: "Invalid" }.to_json)

    response = KLASS.instance.get('abc')

    assert(response.failed?)
    assert_equal({ "error" => "Invalid" }, response.message)
    remove_request_stub(stub)
  end

  def test_rate_limit_response_is_detected
    stub = stub_request(:get, "http://example.com/abc").
            to_return(status: 429, headers: { 'Content-Type': "application/json" }, body: { Message: "Slow down" }.to_json)

    response = KLASS.instance.get('abc')

    assert(response.rate_limit_exceeded?)
    assert_equal("Slow down", response.message)
    remove_request_stub(stub)
  end

  def test_timeout_response_wrapper
    response = HttpApi::Response.new(HttpApi::TimeoutResponse.instance)

    assert_equal(408, response.code)
    assert(response.client_error?)
    assert(!response.success?)
    assert_equal("Timeout", response.response.to_s)
  end

  def test_headers_store_options_and_return_empty_headers
    options = { token: "abc" }
    headers = HttpApi::Headers.new(options)

    assert_same(options, headers.options)
    assert_equal({}, headers.request_headers)
  end

  def test_logger_accessor
    original_logger = HttpApi::Logger.logger
    logger = Object.new

    HttpApi::Logger.logger = logger

    assert_same(logger, HttpApi::Logger.logger)
  ensure
    HttpApi::Logger.logger = original_logger
  end

  private

  def capture_log_calls
    original_log = HttpApi::Logger.method(:log)
    calls = []

    HttpApi::Logger.define_singleton_method(:log) do |url, method, path, request_options, response|
      calls << [url, method, path, request_options.dup, response]
    end

    yield
    calls
  ensure
    HttpApi::Logger.define_singleton_method(:log) do |url, method, path, request_options, response|
      original_log.call(url, method, path, request_options, response)
    end
  end
end
