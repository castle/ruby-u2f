module U2F
  module RequestBase
    attr_accessor :version, :challenge, :app_id

    def version
      'U2F_V2'
    end
  end
end
