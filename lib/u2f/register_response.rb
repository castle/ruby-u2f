module U2F
  ##
  # Representation of a U2F registration response.
  # See chapter 4.3:
  # http://fidoalliance.org/specs/fido-u2f-raw-message-formats-v1.0-rd-20141008.pdf
  class RegisterResponse
    attr_accessor :client_data, :client_data_json, :registration_data_raw

    PUBLIC_KEY_OFFSET = 1
    PUBLIC_KEY_LENGTH = 65
    KEY_HANDLE_LENGTH_LENGTH = 1
    KEY_HANDLE_LENGTH_OFFSET = PUBLIC_KEY_OFFSET + PUBLIC_KEY_LENGTH
    KEY_HANDLE_OFFSET = KEY_HANDLE_LENGTH_OFFSET + KEY_HANDLE_LENGTH_LENGTH

    def self.load_from_json(json)
      # TODO: validate
      data = JSON.parse(json)

      if data['errorCode'] && data['errorCode'] > 0
        fail RegistrationError, :code => data['errorCode']
      end

      instance = new
      instance.client_data_json =
        ::U2F.urlsafe_decode64(data['clientData'])
      instance.client_data =
        ClientData.load_from_json(instance.client_data_json)
      instance.registration_data_raw =
        ::U2F.urlsafe_decode64(data['registrationData'])
      instance
    end

    ##
    # The attestation certificate in Base64 encoded X.509 DER format
    def certificate
      Base64.strict_encode64(parsed_certificate.to_der)
    end

    ##
    # The parsed attestation certificate
    def parsed_certificate
      OpenSSL::X509::Certificate.new(certificate_bytes)
    end

    ##
    # Length of the attestation certificate
    def certificate_length
      parsed_certificate.to_der.bytesize
    end

    ##
    # Returns the key handle from registration data, URL safe base64 encoded
    def key_handle
      ::U2F.urlsafe_encode64(key_handle_raw)
    end

    def key_handle_raw
      registration_data_raw.byteslice(KEY_HANDLE_OFFSET, key_handle_length)
    end

    ##
    # Returns the length of the key handle, extracted from the registration data
    def key_handle_length
      registration_data_raw.byteslice(KEY_HANDLE_LENGTH_OFFSET).unpack('C').first
    end

    ##
    # Returns the public key, extracted from the registration data
    def public_key
      # Base64 encode without linefeeds
      Base64.strict_encode64(public_key_raw)
    end

    def public_key_raw
      registration_data_raw.byteslice(PUBLIC_KEY_OFFSET, PUBLIC_KEY_LENGTH)
    end

    ##
    # Returns the signature, extracted from the registration data
    def signature
      registration_data_raw.byteslice(
        (KEY_HANDLE_OFFSET + key_handle_length + certificate_length)..-1)
    end

    ##
    # Verifies the registration data against the app id
    def verify(app_id)
      # Chapter 4.3 in
      # http://fidoalliance.org/specs/fido-u2f-raw-message-formats-v1.0-rd-20141008.pdf
      data = [
        "\x00",
        ::U2F::DIGEST.digest(app_id),
        ::U2F::DIGEST.digest(client_data_json),
        key_handle_raw,
        public_key_raw
      ].join

      begin
        parsed_certificate.public_key.verify(::U2F::DIGEST.new, signature, data)
      rescue OpenSSL::PKey::PKeyError
        false
      end
    end

    private

    def certificate_bytes
      base_offset = KEY_HANDLE_OFFSET + key_handle_length
      registration_data_raw.byteslice(base_offset..-1)
    end
  end
end
