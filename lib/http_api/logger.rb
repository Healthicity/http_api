# frozen_string_literal: true

module HttpApi
  class Logger
    cattr_accessor :logger

    def self.log(url, method, path, request_options, response)
    end
  end
end
