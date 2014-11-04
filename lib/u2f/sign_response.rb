module U2F
  class SignResponse
    attr_accessor :client_data, :client_data_json, :key_handle, :signature_data

    def self.create_from_json(json)
      data = ::JSON.parse(json)
      instance = new
      instance.client_data_json =
        Base64.urlsafe_decode64(data['clientData'])
      instance.client_data =
        ClientData.create_from_json(instance.client_data_json)
      instance.key_handle = data['keyHandle']
      instance.signature_data =
        Base64.urlsafe_decode64(data['signatureData'])
      instance
    end

    def counter
      # FIXME
      signature_data[1..4].unpack('N').first
    end

    def signature
      signature_data.byteslice(5..-1)
    end

    def verify(app_id, public_key_pem)
      data = [
        Digest::SHA256.digest(app_id),
        signature_data.byteslice(0, 5),
        Digest::SHA256.digest(client_data_json)
      ].join

      public_key = OpenSSL::PKey.read(public_key_pem)
      public_key.verify(OpenSSL::Digest::SHA256.new, signature, data)
    end
  end
end
