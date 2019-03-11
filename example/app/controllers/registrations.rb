# frozen_string_literal: true

U2FExample::App.controllers :registrations do
  get :new do
    @registration_requests = u2f.registration_requests
    session[:challenges] = @registration_requests.map(&:challenge)

    key_handles = Registration.map(&:key_handle)
    @sign_requests = u2f.authentication_requests(key_handles)

    @app_id = u2f.app_id

    render 'registrations/new'
  end

  post :index do
    response = U2F::RegisterResponse.load_from_json(params[:response])

    begin
      reg = u2f.register!(session[:challenges], response)

      Registration.create!(
        certificate: reg.certificate,
        key_handle: reg.key_handle,
        public_key: reg.public_key,
        counter: reg.counter
      )
    rescue U2F::Error => e
      @error_message = "Unable to register: #{e.class.name}"
    ensure
      session.delete(:challenges)
    end

    render 'authentications/show'
  end
end
