module U2F
  class U2F
    attr_accessor :app_id
    def initialize(app_id)
      @app_id = app_id
    end

    ##
    # Generate data to be sent to the U2F device before authenticating
    def authentication_requests(key_handles)
      key_handles = [key_handles] unless key_handles.is_a? Array
      sign_requests = key_handles.map do |key_handle|
        SignRequest.new(key_handle, challenge, app_id)
      end
      Collection.new(sign_requests)
    end

    ##
    # Authenticate a response from the U2F device
    def authenticate!(challenges, response, registration_public_key,
                      registration_counter)
      # Handle both single and Array input
      challenges = [challenges] unless challenges.is_a? Array

      # TODO: check that it's the correct key_handle as well
      unless challenges.include?(response.client_data.challenge)
        fail NoMatchingRequestError
      end

      fail ClientDataTypeError unless response.client_data.authentication?

      pem = U2F.public_key_pem(registration_public_key)

      fail AuthenticationFailedError unless response.verify(app_id, pem)

      fail UserNotPresentError unless response.user_present?

      unless response.counter > registration_counter
        fail CounterToLowError
      end
    end

    ##
    # Generates a 32 byte long random U2F challenge
    def challenge
      Base64.urlsafe_encode64(SecureRandom.random_bytes(32))
    end

    ##
    # Generate data to be used when registering a U2F device
    def registration_requests
      # TODO: generate a request for each supported version
      Collection.new(RegisterRequest.new(challenge, @app_id))
    end

    ##
    # Authenticate the response from the U2F device when registering
    # Returns a registration object
    def register!(challenges, response)
      challenges = [challenges] unless challenges.is_a? Array
      challenge = challenges.detect do |chg|
        chg == response.client_data.challenge
      end

      fail UnmatchedChallengeError unless challenge

      fail ClientDataTypeError unless response.client_data.registration?

      # Validate public key
      U2F.public_key_pem(response.public_key_raw)

      unless U2F.validate_certificate(response.certificate_raw)
        fail AttestationVerificationError
      end

      fail AttestationSignatureError unless response.verify(app_id)

      registration = Registration.new(
        response.key_handle,
        response.public_key,
        response.certificate
      )
      registration
    end

    def private_key
      # TODO: configure loading of private key
      OpenSSL::PKey::RSA.new 'key_pem', 'pass_phrase'
    end

    ##
    # Convert a binary public key to PEM format
    def self.public_key_pem(key)
      fail PublicKeyDecodeError unless key.length == 65 || key[0] == "\x04"
      # http://tools.ietf.org/html/rfc5480
      der = OpenSSL::ASN1::Sequence([
        OpenSSL::ASN1::Sequence([
          OpenSSL::ASN1::ObjectId('1.2.840.10045.2.1'),  # id-ecPublicKey
          OpenSSL::ASN1::ObjectId('1.2.840.10045.3.1.7') # secp256r1
        ]),
        OpenSSL::ASN1::BitString(key)
      ]).to_der

      pem = "-----BEGIN PUBLIC KEY-----\r\n" +
            Base64.strict_encode64(der).scan(/.{1,64}/).join("\r\n") +
            "\r\n-----END PUBLIC KEY-----"
      pem
    end

    def self.validate_certificate(certificate_raw)
      # TODO
      return true
      # cacert = OpenSSL::X509::Certificate.new()
      # cert = OpenSSL::X509::Certificate.new(certificate_raw)
      # cert.verify(cacert.public_key)
    end
  end
end
