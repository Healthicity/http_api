# frozen_string_literal: true

require "test_helper"

class HttpApiTest < Test::Unit::TestCase
  
  KLASS = Class.new do
    include HttpApi::Request
    include Singleton
    
    def get(path, options = {})
      perform_get(path, options = {})
    end

    def post(path, options = {})
      perform_post(path, options = {})
    end
    

    def put(path, options = {})
      perform_put(path, options = {})
    end
    
    def delete(path, options = {})
      perform_delete(path, options = {})
    end

    def url
      "http://example.com"
    end
    
  end 

  def test_get
    stub = stub_request(:get, "http://example.com/abc").
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    KLASS.instance.get('abc')
    remove_request_stub(stub)
  end

  def test_post
    stub = stub_request(:post, "http://example.com/abc").
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    KLASS.instance.post('abc')
    remove_request_stub(stub)
  end

  def test_put
    stub = stub_request(:put, "http://example.com/abc").
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    KLASS.instance.put('abc')
    remove_request_stub(stub)
  end

  def test_delete
    stub = stub_request(:delete, "http://example.com/abc").
            to_return(status: 200, headers: { 'Content-Type': "application/json" }, body: {}.to_json)

    KLASS.instance.delete('abc')
    remove_request_stub(stub)
  end
end
