module U2F
  class RegisterRequest
    include RequestBase

    def initialize(challenge, app_id)
      @challenge = challenge
      @app_id = app_id
    end
  end
end