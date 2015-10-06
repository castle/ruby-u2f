module U2F
  class U2F
    attr_accessor :app_id
    ##
    # * *Args*:
    #   - +app_id+:: An application (facet) ID string
    #
    def initialize(app_id)
      @app_id = app_id
    end

    ##
    # Generate data to be sent to the U2F device before authenticating
    #
    # * *Args*:
    #   - +key_handles+:: +Array+ of previously registered U2F key handles
    #
    # * *Returns*:
    #   - An +Array+ of +SignRequest+ objects
    #
    def authentication_requests(key_handles)
      key_handles = [key_handles] unless key_handles.is_a? Array
      key_handles.map do |key_handle|
        SignRequest.new(key_handle, challenge, app_id)
      end
    end

    ##
    # Authenticate a response from the U2F device
    #
    # * *Args*:
    #   - +challenges+:: +Array+ of challenge strings
    #   - +response+:: Response from the U2F device as a +SignResponse+ object
    #   - +registration_public_key+:: Public key of the registered U2F device as binary string
    #   - +registration_counter+:: +Integer+ with the current counter value of the registered device.
    #
    # * *Raises*:
    #   - +NoMatchingRequestError+:: if the challenge in the response doesn't match any of the provided ones.
    #   - +ClientDataTypeError+:: if the response is of the wrong type
    #   - +AuthenticationFailedError+:: if the authentication failed
    #   - +UserNotPresentError+:: if the user wasn't present during the authentication
    #   - +CounterTooLowError+:: if there is a counter mismatch between the registered one and the one in the response.
    #
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
        unless response.counter == 0 && registration_counter == 0
          fail CounterTooLowError
        end
      end
    end

    ##
    # Generates a 32 byte long random U2F challenge
    #
    # * *Returns*:
    #   - Base64 urlsafe encoded challenge
    #
    def challenge
      ::U2F.urlsafe_encode64(SecureRandom.random_bytes(32))
    end

    ##
    # Generate data to be used when registering a U2F device
    #
    # * *Returns*:
    #   - An +Array+ of +RegisterRequest+ objects
    #
    def registration_requests
      # TODO: generate a request for each supported version
      [RegisterRequest.new(challenge, @app_id)]
    end

    ##
    # Authenticate the response from the U2F device when registering
    #
    # * *Args*:
    #   - +challenges+:: +Array+ of challenge strings
    #   - +response+:: Response of the U2F device as a +RegisterResponse+ object
    #
    # * *Returns*:
    #   - A +Registration+ object
    #
    # * *Raises*:
    #   - +UnmatchedChallengeError+:: if the challenge in the response doesn't match any of the provided ones.
    #   - +ClientDataTypeError+:: if the response is of the wrong type
    #   - +AttestationSignatureError+:: if the registration failed
    #
    def register!(challenges, response)
      challenges = [challenges] unless challenges.is_a? Array
      challenge = challenges.detect do |chg|
        chg == response.client_data.challenge
      end

      fail UnmatchedChallengeError unless challenge

      fail ClientDataTypeError unless response.client_data.registration?

      # Validate public key
      U2F.public_key_pem(response.public_key_raw)

      # TODO:
      # unless U2F.validate_certificate(response.certificate_raw)
      #   fail AttestationVerificationError
      # end

      fail AttestationSignatureError unless response.verify(app_id)

      registration = Registration.new(
        response.key_handle,
        response.public_key,
        response.certificate
      )
      registration
    end

    ##
    # Convert a binary public key to PEM format
    # * *Args*:
    #   - +key+:: Binary public key
    #
    # * *Returns*:
    #   - A base64 encoded public key +String+ in PEM format
    #
    # * *Raises*:
    #   - +PublicKeyDecodeError+:: if the +key+ argument is incorrect
    #
    def self.public_key_pem(key)
      fail PublicKeyDecodeError unless key.bytesize == 65 && key.byteslice(0) == "\x04"
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

    # def self.validate_certificate(_certificate_raw)
      # TODO
      # cacert = OpenSSL::X509::Certificate.new()
      # cert = OpenSSL::X509::Certificate.new(certificate_raw)
      # cert.verify(cacert.public_key)
    # end
  end

  ##
  # Variant of Base64::urlsafe_decode64 which adds padding if necessary
  #
  def self.urlsafe_decode64(string)
    string = case string.length % 4
      when 2 then string + '=='
      when 3 then string + '='
      else
        string
    end
    Base64.urlsafe_decode64(string)
  end

  ##
  # Variant of Base64::urlsafe_encode64 which removes padding
  #
  def self.urlsafe_encode64(string)
    Base64.urlsafe_encode64(string).delete('=')
  end
end
