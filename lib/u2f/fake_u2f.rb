class U2F::FakeU2F
  CURVE_NAME   = "prime256v1".freeze

  attr_accessor :app_id, :counter, :key_handle_raw, :cert_subject

  # Initialize a new FakeU2F device for use in tests.
  #
  # app_id  - The appId/origin this is being tested against.
  # options - A Hash of optional parameters (optional).
  #           :counter      - The initial counter for this device.
  #           :key_handle   - The raw key-handle this device should use.
  #           :cert_subject - The subject field for the certificate generated
  #                           for this device.
  #
  # Returns nothing.
  def initialize(app_id, options = {})
    @app_id = app_id
    @counter = options.fetch(:counter, 0)
    @key_handle_raw = options.fetch(:key_handle, SecureRandom.random_bytes(32))
    @cert_subject = options.fetch(:cert_subject, "/CN=U2FTest")
  end

  # A registerResponse hash as returned by the u2f.register JavaScript API.
  #
  # challenge - The challenge to sign.
  # error     - Boolean. Whether to return an error response (optional).
  #
  # Returns a JSON encoded Hash String.
  def register_response(challenge, error = false)
    if error
      JSON.dump(:errorCode => 4)
    else
      client_data_json = client_data(U2F::ClientData::REGISTRATION_TYP, challenge)
      JSON.dump(
        :registrationData => reg_registration_data(client_data_json),
        :clientData => U2F.urlsafe_encode64(client_data_json)
      )
    end
  end

  # A SignResponse hash as returned by the u2f.sign JavaScript API.
  #
  # challenge - The challenge to sign.
  #
  # Returns a JSON encoded Hash String.
  def sign_response(challenge)
    client_data_json = client_data(U2F::ClientData::AUTHENTICATION_TYP, challenge)
    JSON.dump(
      :clientData => U2F.urlsafe_encode64(client_data_json),
      :keyHandle => U2F.urlsafe_encode64(key_handle_raw),
      :signatureData => auth_signature_data(client_data_json)
    )
  end

  # The appId specific public key as returned in the registrationData field of
  # a RegisterResponse Hash.
  #
  # Returns a binary formatted EC public key String.
  def origin_public_key_raw
    [origin_key.public_key.to_bn.to_s(16)].pack('H*')
  end

  # The raw device attestation certificate as returned in the registrationData
  # field of a RegisterResponse Hash.
  #
  # Returns a DER formatted certificate String.
  def cert_raw
    cert.to_der
  end

  private

  # The registrationData field returns in a RegisterResponse Hash.
  #
  # client_data_json - The JSON encoded clientData String.
  #
  # Returns a url-safe base64 encoded binary String.
  def reg_registration_data(client_data_json)
    U2F.urlsafe_encode64(
      [
        5,
        origin_public_key_raw,
        key_handle_raw.bytesize,
        key_handle_raw,
        cert_raw,
        reg_signature(client_data_json)
      ].pack("CA65CA#{key_handle_raw.bytesize}A#{cert_raw.bytesize}A*")
    )
  end

  # The signature field of a registrationData field of a RegisterResponse.
  #
  # client_data_json - The JSON encoded clientData String.
  #
  # Returns an ECDSA signature String.
  def reg_signature(client_data_json)
    payload = [
      "\x00",
      U2F::DIGEST.digest(app_id),
      U2F::DIGEST.digest(client_data_json),
      key_handle_raw,
      origin_public_key_raw
    ].join
    cert_key.sign(U2F::DIGEST.new, payload)
  end

  # The signatureData field of a SignResponse Hash.
  #
  # client_data_json - The JSON encoded clientData String.
  #
  # Returns a url-safe base64 encoded binary String.
  def auth_signature_data(client_data_json)
    ::U2F.urlsafe_encode64(
      [
        1, # User present
        self.counter += 1,
        auth_signature(client_data_json)
      ].pack("CNA*")
    )
  end

  # The signature field of a signatureData field of a SignResponse Hash.
  #
  # client_data_json - The JSON encoded clientData String.
  #
  # Returns an ECDSA signature String.
  def auth_signature(client_data_json)
    data = [
      U2F::DIGEST.digest(app_id),
      1, # User present
      counter,
      U2F::DIGEST.digest(client_data_json)
    ].pack("A32CNA32")

    origin_key.sign(U2F::DIGEST.new, data)
  end

  # The clientData hash as returned by registration and authentication
  # responses.
  #
  # typ       - The String value for the 'typ' field.
  # challenge - The String url-safe base64 encoded challenge parameter.
  #
  # Returns a JSON encoded Hash String.
  def client_data(typ, challenge)
    JSON.dump(
      :challenge => challenge,
      :origin    => app_id,
      :typ       => typ
    )
  end

  # The appId-specific public/private key.
  #
  # Returns a OpenSSL::PKey::EC instance.
  def origin_key
    @origin_key ||= generate_ec_key
  end

  # The self-signed device attestation certificate.
  #
  # Returns a OpenSSL::X509::Certificate instance.
  def cert
    @cert ||= OpenSSL::X509::Certificate.new.tap do |c|
      c.subject = c.issuer = OpenSSL::X509::Name.parse(cert_subject)
      c.not_before = Time.now
      c.not_after = Time.now + 365 * 24 * 60 * 60
      c.public_key = cert_key
      c.serial = 0x1
      c.version = 0x0
      c.sign cert_key, U2F::DIGEST.new
    end
  end

  # The public key used for signing the device certificate.
  #
  # Returns a OpenSSL::PKey::EC instance.
  def cert_key
    @cert_key ||= generate_ec_key
  end

  # Generate an eliptic curve public/private key.
  #
  # Returns a OpenSSL::PKey::EC instance.
  def generate_ec_key
    OpenSSL::PKey::EC.new().tap do |ec|
      ec.group = OpenSSL::PKey::EC::Group.new(CURVE_NAME)
      ec.generate_key
      # https://bugs.ruby-lang.org/issues/8177
      ec.define_singleton_method(:private?) { private_key? }
      ec.define_singleton_method(:public?) { public_key? }
    end
  end
end
