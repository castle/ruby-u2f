module U2F
  class RegisterResponse
    attr_accessor :client_data
    attr_accessor :registration_data

    def self.create_from_json(json)
      data = JSON.parse(json)
      instance = new self
      instance.client_data = data['clientData']
      instance.registration_data = data['registrationData']
      instance
    end
  end
end
