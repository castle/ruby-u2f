module U2F
  class U2FError < StandardError;end
  class UnmatchedChallengeError < U2FError;end
  class CertificateDecodeError < U2FError;end
  class PublicKeyDecodeError < U2FError;end
  class AttestationVerificationError < U2FError;end
  class AttestationSignatureError < U2FError;end
  class NoMatchingRequestError < U2FError;end
  class NoMatchingRegistrationError < U2FError;end
  class CounterToLowError < U2FError;end
  class AuthenticationFailedError < U2FError;end
end