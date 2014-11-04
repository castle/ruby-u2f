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
  class CounterToLowError < Error; end
  class AuthenticationFailedError < Error; end
  class UserNotPresentError < Error;end
end
