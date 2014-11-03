module U2F
  class U2F
    attr_accessor :app_id
    def initialize(app_id)
      @app_id = app_id
    end

    ##
    # Generate data to be sent to the U2F device before authenticating
    def authentication_data(key_handles)
      key_handles = [key_handles] unless key_handles.is_a? Array
      key_handles.each do |key_handle|
        SignRequest.new(key_handle, challenge, app_id)
      end
    end

    ##
    # Authenticate a response from the U2F device
    def authenticate!(requests, registrations, response)
      # Handle both single and Array input
      requests = [requests] unless requests.is_a? Array
      registrations = [registrations] unless registrations.is_a? Array

      # Find a request that matches the response key_handle and challenge
      request = requests.detect do |req|
        req.key_handle == response.key_handle &&
        req.challenge == response.client_data['challenge']
      end

      fail NoMatchingRequestError unless request

      # Find a registration that matches the response key_handle
      registration = registrations.detect do |reg|
        reg.key_handle == response.key_handle
      end

      fail NoMatchingRegistrationError unless registration

      pem = U2F.public_key_pem(registration.public_key)

      fail AuthenticationFailedError unless response.verify(app_id, pem)

      if response.counter > registration.counter
        registration.counter = response.counter
      else
        fail CounterToLowError
      end

      registration
    end

    ##
    # Generates a 32 byte long random U2F challenge
    def challenge
      Base64.urlsafe_encode64(SecureRandom.random_bytes(32))
    end

    ##
    # Generate data to be used when registering a U2F device
    def registration_data(key_handles = [])
      [
        RegisterRequest.new(challenge, @app_id),
        authenticate_data(key_handles)
      ]
    end

    ##
    # Authenticate the response from the U2F device when registering
    # Returns a registration object
    def register!(request, response)
      unless request.challenge == response.challenge
        fail UnmatchedChallengeError
      end

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

      der = "\x30\x59\x30\x13\x06\x07\x2a\x86\x48\xce\x3d\x02\x01".force_encoding('ASCII-8BIT') <<
            "\x06\x08\x2a\x86\x48\xce\x3d\x03\x01\x07\x03\x42".force_encoding('ASCII-8BIT') <<
            "\0".force_encoding('ASCII-8BIT') << key

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
