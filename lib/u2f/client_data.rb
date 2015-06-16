module U2F
  ##
  # A representation of ClientData, chapter 7
  # http://fidoalliance.org/specs/fido-u2f-raw-message-formats-v1.0-rd-20141008.pdf
  class ClientData
    REGISTRATION_TYP   = "navigator.id.finishEnrollment".freeze
    AUTHENTICATION_TYP = "navigator.id.getAssertion".freeze

    attr_accessor :typ, :challenge, :origin
    alias_method :type, :typ

    def registration?
      typ == REGISTRATION_TYP
    end

    def authentication?
      typ == AUTHENTICATION_TYP
    end

    def self.load_from_json(json)
      client_data = ::JSON.parse(json)
      instance = new
      instance.typ = client_data['typ']
      instance.challenge = client_data['challenge']
      instance.origin = client_data['origin']
      instance
    end
  end
end
