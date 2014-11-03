module U2F
  module RequestBase
    attr_accessor :version, :challenge, :app_id

    def as_json
      {
        version: version,
        challenge: challenge,
        appId: app_id
      }
    end

    def to_json
      ::JSON.dump(as_json)
    end

    def version
      'U2F_V2'
    end
  end
end
