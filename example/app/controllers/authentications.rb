require 'base64'
U2FExample::App.controllers :authentications do
  get :new do
    key_handles = Registration.map(&:key_handle)
    return 'Need to register first' if key_handles.empty?

    @sign_requests = u2f.authentication_requests(key_handles)
    session[:challenges] = @sign_requests.map(&:challenge)

    render 'authentications/new'
  end

  post :index do
    response = U2F::SignResponse.load_from_json(params[:response])

    registration = Registration.first(key_handle: response.key_handle)
    return 'Need to register first' unless registration

    begin
      u2f.authenticate!(session[:challenges], response,
                        Base64.decode64(registration.public_key),
                        registration.counter)
    rescue U2F::Error => e
      @error_message = "Unable to authenticate: #{e.class.name}"
    ensure
      session.delete(:challenges)
    end

    registration.update(counter: response.counter)

    render 'authentications/show'
  end
end
