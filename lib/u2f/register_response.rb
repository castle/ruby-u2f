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
      Base64.strict_encode64(certificate_raw)
    end

    ##
    # Length of the attestation certificate
    def certificate_length
      # http://en.wikipedia.org/wiki/Abstract_Syntax_Notation_One#Example_encoded_in_DER
      #
      # Do some quick parsing of the certificate DER format.
      # First bytes (TLV) could be ex:
      # T 0x30: SEQUENCE Tag
      # L 0x82: Length (2 length bytes)
      #   0x02 0xe2: Two bytes indicated by the L byte.
      #              Makes up the data length 738 (which makes 742 in total)

      t_byte = certificate_bytes(0)

      fail AttestationDecodeError unless t_byte == "\x30"

      l_byte = certificate_bytes(1).unpack('c').first # 8-bit signed integer
      # If the L-byte has MSB set to 1 (ie. < 0) the value will tell how many
      # following bytes is used to describe the total length. Otherwise it will
      # describe the data length
      # http://msdn.microsoft.com/en-us/library/windows/desktop/bb648641(v=vs.85).aspx

      nbr_length_bytes = 0
      cert_length = if l_byte < 0
        nbr_length_bytes = l_byte + 0x80 # last 7-bits is the number of bytes
        length_bytes = certificate_bytes(2, nbr_length_bytes).unpack('C*')
        length_bytes.reverse.each_with_index.inject(0) do |sum, (val, idx)|
          sum + (val << (8*idx))
        end
      else
        l_byte
      end

      cert_length + nbr_length_bytes + 2 # Make up for the T and L bytes them selves
    end

    ##
    # The attestation certificate in X.509 DER format
    def certificate_raw
      certificate_bytes(0, certificate_length)
    end

    ##
    # Returns the key handle from registration data, URL safe base64 encoded
    def key_handle
      Base64.urlsafe_encode64(key_handle_raw)
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
    # Verifies the registration data agains the app id
    def verify(app_id)
      # Chapter 4.3 in
      # http://fidoalliance.org/specs/fido-u2f-raw-message-formats-v1.0-rd-20141008.pdf
      data = [
        "\x00",
        Digest::SHA256.digest(app_id),
        Digest::SHA256.digest(client_data_json),
        key_handle_raw,
        public_key_raw
      ].join

      cert = OpenSSL::X509::Certificate.new(certificate_raw)
      cert.public_key.verify(OpenSSL::Digest::SHA256.new, signature, data)
    end

    private

    def certificate_bytes(offset, length = 1)
      base_offset = KEY_HANDLE_OFFSET + key_handle_length
      registration_data_raw.byteslice(base_offset + offset, length)
    end
  end
end
