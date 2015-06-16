module U2F
  module RequestBase
    attr_accessor :version, :challenge, :app_id

    def as_json(options = {})
      {
        version: version,
        challenge: challenge,
        appId: app_id
      }
    end

    def to_json(options = {})
      ::JSON.pretty_generate(as_json, options)
    end

    def version
      'U2F_V2'
    end
  end
end
