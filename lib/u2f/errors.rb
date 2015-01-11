module U2F
  class Error < StandardError;end
  class UnmatchedChallengeError < Error; end
  class ClientDataTypeError < Error; end
  class PublicKeyDecodeError < Error; end
  class AttestationDecodeError < Error; end
  class AttestationVerificationError < Error; end
  class AttestationSignatureError < Error; end
  class NoMatchingRequestError < Error; end
  class NoMatchingRegistrationError < Error; end
  class CounterTooLowError < Error; end
  class AuthenticationFailedError < Error; end
  class UserNotPresentError < Error;end

  class RegistrationError < Error
    CODES = {
      1 => "OTHER_ERROR",
      2 => "BAD_REQUEST",
      3 => "CONFIGURATION_UNSUPPORTED",
      4 => "DEVICE_INELIGIBLE",
      5 => "TIMEOUT"
    }

    attr_reader :code

    def initialize(options = {})
      @code = options[:code]
      message = options[:message] || "Token returned #{CODES[code]}"
      super(message)
    end
  end
end
