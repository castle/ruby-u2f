module U2F
  class SignResponse
    attr_accessor :client_data, :key_handle, :signature_data

    def self.create_from_json(json)
      data = ::JSON.parse(json)
      instance = self.new
      instance.client_data =
        ::JSON.parse(Base64.urlsafe_decode64(data['clientData']))
      instance.key_handle = data['keyHandle']
      instance.signature_data =
        Base64.urlsafe_decode64(data['signatureData'])
      instance
    end

    def counter
      signature_data[1..4].unpack('Nctr')
    end

    def signature
      signature_data.byteslice(5..-1)
    end

    def verify(app_id, public_key_pem)
      data = [
        Digest::SHA256.digest(app_id),
        signature_data.byteslice(0, 5),
        client_data
      ].join

      public_key = OpenSSL::PKey.read(public_key_pem)
      public_key.verify(OpenSSL::Digest::SHA256.new, signature, data)
    end
  end
end
