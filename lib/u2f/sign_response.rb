module U2F
  class SignResponse
    attr_accessor :client_data, :client_data_json, :key_handle, :signature_data

    def self.load_from_json(json)
      data = ::JSON.parse(json)
      if !data.key?('clientData') || !data.key?('keyHandle') ||
         !data.key?('signatureData')
        raise Error, 'Missing required data'
      end

      instance = new
      instance.client_data_json =
        ::U2F.urlsafe_decode64(data['clientData'])
      instance.client_data =
        ClientData.load_from_json(instance.client_data_json)
      instance.key_handle = data['keyHandle']
      instance.signature_data =
        ::U2F.urlsafe_decode64(data['signatureData'])
      instance
    end

    ##
    # Counter value that the U2F token increments every time it performs an
    # authentication operation
    def counter
      signature_data.byteslice(1, 4).unpack('N').first
    end

    ##
    # signature is to be verified using the public key obtained during
    # registration.
    def signature
      signature_data.byteslice(5..-1)
    end

    # Bit 0 being set to 1 indicates that the user is present. A different value
    # of Bit 0, as well as Bits 1 through 7, are reserved for future use.
    USER_PRESENCE_MASK = 0b00000001

    ##
    # If user presence was verified
    def user_present?
      byte = signature_data.byteslice(0).unpack('C').first
      byte & USER_PRESENCE_MASK == 1
    end

    ##
    # Verifies the response against an app id and the public key of the
    # registered device
    def verify(app_id, public_key_pem)
      data = [
        ::U2F::DIGEST.digest(app_id),
        signature_data.byteslice(0, 5),
        ::U2F::DIGEST.digest(client_data_json)
      ].join

      public_key = OpenSSL::PKey.read(public_key_pem)

      begin
        public_key.verify(::U2F::DIGEST.new, signature, data)
      rescue OpenSSL::PKey::PKeyError
        false
      end
    end
  end
end
