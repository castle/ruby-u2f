# frozen_string_literal: true

module U2F
  class RegisterRequest
    include RequestBase
    attr_accessor :challenge

    def initialize(challenge)
      @challenge = challenge
    end

    def as_json(_options = {})
      {
        version: version,
        challenge: challenge
      }
    end
  end
end
