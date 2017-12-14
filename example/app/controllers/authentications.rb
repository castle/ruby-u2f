# frozen_string_literal: true

require 'base64'
U2FExample::App.controllers :authentications do
  get :new do
    key_handles = Registration.map(&:key_handle)
    return 'Need to register first' if key_handles.empty?

    @app_id = u2f.app_id
    @sign_requests = u2f.authentication_requests(key_handles)
    @challenge = u2f.challenge
    session[:u2f_challenge] = @challenge

    render 'authentications/new'
  end

  post :index do
    response = U2F::SignResponse.load_from_json(params[:response])

    registration = Registration.first(key_handle: response.key_handle)
    return 'Need to register first' unless registration

    begin
      u2f.authenticate!(session[:u2f_challenge], response,
                        Base64.decode64(registration.public_key),
                        registration.counter)
    rescue U2F::Error => e
      @error_message = "Unable to authenticate: #{e.class.name}"
    ensure
      session.delete(:u2f_challenge)
    end

    registration.update(counter: response.counter)

    render 'authentications/show'
  end
end
