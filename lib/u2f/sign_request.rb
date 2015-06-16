module U2F
  class SignRequest
    include RequestBase
    attr_accessor :key_handle

    def initialize(key_handle, challenge, app_id)
      @key_handle = key_handle
      @challenge = challenge
      @app_id = app_id
    end

    def as_json(options = {})
      super.merge(keyHandle: key_handle)
    end
  end
end
