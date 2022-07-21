# frozen_string_literal: true

module HttpApi
  class TimeoutResponse
    include Singleton

    delegate :ok?,
             :created?,
             :no_content?,
             :bad_request?,
             :unauthorized?,
             :too_many_requests?,
             :client_error?,
             :server_error?, to: :status

    def code
      408
    end

    def status
      HTTP::Response::Status.new(408)
    end

    def to_s
      "Timeout"
    end
  end
end
