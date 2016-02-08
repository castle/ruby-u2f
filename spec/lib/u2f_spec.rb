 require 'spec_helper'

describe U2F do
  let(:app_id) { 'http://demo.example.com' }
  let(:device_challenge) { U2F.urlsafe_encode64(SecureRandom.random_bytes(32)) }
  let(:auth_challenge) { device_challenge }
  let(:u2f) { U2F::U2F.new(app_id) }
  let(:device) { U2F::FakeU2F.new(app_id) }
  let(:key_handle) { U2F.urlsafe_encode64(device.key_handle_raw) }
  let(:certificate) { Base64.strict_encode64(device.cert_raw) }
  let(:public_key) { device.origin_public_key_raw }
  let(:register_response_json) { device.register_response(device_challenge) }
  let(:sign_response_json) { device.sign_response(device_challenge) }
  let(:registration) do
    U2F::Registration.new(key_handle, public_key, certificate)
  end
  let(:register_response) do
    U2F::RegisterResponse.load_from_json(register_response_json)
  end
  let(:sign_response) do
    U2F::SignResponse.load_from_json sign_response_json
  end
  let(:sign_request) do
    U2F::SignRequest.new(key_handle)
  end

  describe '#authentication_requests' do
    let(:requests) { u2f.authentication_requests(key_handle) }
    it 'returns an array of requests' do
      expect(requests).to be_an Array
      requests.each { |r| expect(r).to be_a U2F::SignRequest }
    end
  end

  describe '#authenticate!' do
    let(:counter) { registration.counter }
    let(:reg_public_key) { registration.public_key }
    let (:u2f_authenticate) do
      u2f.authenticate!(auth_challenge, sign_response, reg_public_key, counter)
    end
    context 'with correct parameters' do
      it 'does not raise an error' do
        expect { u2f_authenticate }.to_not raise_error
      end
    end

    context 'with incorrect challenge' do
      let(:auth_challenge) { 'incorrect' }
      it 'raises NoMatchingRequestError' do
        expect { u2f_authenticate }.to raise_error(U2F::NoMatchingRequestError)
      end
    end

    context 'with incorrect counter' do
      let(:counter) { 1000 }
      it 'raises CounterTooLowError' do
        expect { u2f_authenticate }.to raise_error(U2F::CounterTooLowError)
      end
    end
    context 'with incorrect counter' do
      let(:reg_public_key) { "\x00" }
      it 'raises CounterToLowError' do
        expect { u2f_authenticate }.to raise_error(U2F::PublicKeyDecodeError)
      end
    end
  end

  describe '#registration_requests' do
    let(:requests) { u2f.registration_requests }
    it 'returns an array of requests' do
      expect(requests).to be_an Array
      requests.each { |r| expect(r).to be_a U2F::RegisterRequest }
    end
  end

  describe '#register!' do
    context 'with correct registration data' do
      it 'returns a registration' do
        reg = nil
        expect {
          reg = u2f.register!(auth_challenge, register_response)
        }.to_not raise_error
        expect(reg.key_handle).to eq key_handle
      end

      it 'accepts an array of challenges' do
        reg = u2f.register!(['another-challenge', auth_challenge], register_response)
        expect(reg).to be_a U2F::Registration
      end
    end

    context 'with unknown challenge' do
      let(:auth_challenge) { 'non-matching' }
      it 'raises an UnmatchedChallengeError' do
        expect {
          u2f.register!(auth_challenge, register_response)
        }.to raise_error(U2F::UnmatchedChallengeError)
      end
    end
  end

  describe '::public_key_pem' do
    context 'with correct key' do
      it 'wraps the result' do
        pem = U2F::U2F.public_key_pem public_key
        expect(pem).to start_with '-----BEGIN PUBLIC KEY-----'
        expect(pem).to end_with '-----END PUBLIC KEY-----'
      end
    end

    context 'with invalid key' do
      let(:public_key) { U2F.urlsafe_decode64('YV6FVSmH0ObY1cBRCsYJZ/CXF1gKsL+DW46rMfpeymtDZted2Ut2BraszUK1wg1+YJ4Bxt6r24WHNUYqKgeaSq8=') }
      it 'fails when first byte of the key is not 0x04' do
        expect {
          U2F::U2F.public_key_pem public_key
        }.to raise_error(U2F::PublicKeyDecodeError)
      end
    end

    context 'with truncated key' do
      let(:public_key) { U2F.urlsafe_decode64('BJhSPkR3Rmgl') }
      it 'fails when key is to short' do
        expect {
          U2F::U2F.public_key_pem public_key
        }.to raise_error(U2F::PublicKeyDecodeError)
      end
    end
  end
end
