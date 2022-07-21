module HttpApi
  class Response

    attr_reader :response

    delegate :code, :mime_type, :status, to: :response
    delegate :ok?,
             :created?,
             :no_content?,
             :bad_request?,
             :unauthorized?,
             :too_many_requests?,
             :client_error?,
             :server_error?, to: :status

    def initialize(response)
      @response = response
    end

    def success?
      ok? || no_content? || created?
    end

    def failed?
      bad_request?
    end

    def rate_limit_exceeded?
      too_many_requests?
    end

    def message
      success? ? success_message : failure_message
    end

    def parse_response
      @_parse_response ||= JSON.parse(response)
    end

    private

    def mime_type_present?
      mime_type
    end

    # check for the presence of mime_type before parsing
    # responses with non content body have no mime_type
    # example: logout api endpoint
    def success_message
      parse_response if mime_type_present?
    end

    def failure_message
      parse_response["Message"] || parse_response
    end

  end
end
