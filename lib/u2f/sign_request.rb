# frozen_string_literal: true

module U2F
  class SignRequest
    include RequestBase
    attr_accessor :key_handle

    def initialize(key_handle)
      @key_handle = key_handle
    end

    def as_json(_options = {})
      {
        version: version,
        keyHandle: key_handle
      }
    end
  end
end
