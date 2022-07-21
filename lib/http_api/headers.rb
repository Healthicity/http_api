module HttpApi
  class Headers

    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    def request_headers
      {}
    end
  end
end