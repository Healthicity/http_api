# frozen_string_literal: true

require_relative "timeout_response"
require_relative "response"
require_relative "headers"
require_relative "logger"

module HttpApi
  module Request
    def perform_get(path, options = {})
      perform_request(:get, path, options)
    end

    def perform_post(path, options = {})
      perform_request(:post, path, options)
    end

    def perform_put(path, options = {})
      perform_request(:put, path, options)
    end

    def perform_delete(path, options = {})
      perform_request(:delete, path, options)
    end

    protected

      def url
        raise NotImplementedError
      end

      def default_options
        {}
      end

    private

      def perform_request(method, path, options = {})
        tries ||= 3

        if options.respond_to?(:merge!)
          options.merge!(default_options)
        end

        response = send_request(method, path, options)
        log_response(url, method, path, options, (response.parse rescue ""))

        response_with_wrapper(response)
      rescue HTTP::TimeoutError => e
        sleep (4 - tries)
        retry unless (tries -= 1).zero?
        log_response(url, method, path, options, "TIMEOUT")
        response_with_wrapper(HttpApi::TimeoutResponse.instance)
      end

      def send_request(method, path, options = {})
        headers = request_headers(options)

        options_key = if method == :get
                        :params
                      else
                        options.is_a?(Hash) && options[:parameter_passing_option].present? ? options.delete(:parameter_passing_option) : :json
                      end

        uri = "#{url}/#{path}"
        http_client.headers(headers).public_send(method, uri, options_key => options)
      end

      def http_client
        HTTP.timeout(:per_operation, write: 2, connect: 5, read: 10)
      end

      def log_response(url, method, path, request_options, response)
        HttpApi::Logger.log(url, method, path, request_options, response)
      end

      def request_headers(options)
        HttpApi::Headers.new(options).request_headers
      end

      def response_with_wrapper(response)
        HttpApi::Response.new(response)
      end
  end
end
