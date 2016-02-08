require 'spec_helper.rb'

describe U2F::RegisterResponse do
  let(:app_id) { 'http://demo.example.com' }
  let(:challenge) { U2F.urlsafe_encode64(SecureRandom.random_bytes(32)) }
  let(:device) { U2F::FakeU2F.new(app_id) }
  let(:key_handle) { U2F.urlsafe_encode64(device.key_handle_raw) }
  let(:public_key) { Base64.strict_encode64(device.origin_public_key_raw) }
  let(:certificate) { Base64.strict_encode64(device.cert_raw) }
  let(:registration_data_json) { device.register_response(challenge) }
  let(:registration_data_json_without_padding) do
    device.register_response(challenge).gsub(" ", "")
  end
  let(:error_response) { device.register_response(challenge, error = true) }
  let(:registration_request) { U2F::RegisterRequest.new(challenge) }
  let(:register_response) do
    U2F::RegisterResponse.load_from_json(registration_data_json)
  end

  context 'with error response' do
    let(:registration_data_json) { error_response }
    it 'raises RegistrationError with code' do
      expect {
        register_response
      }.to raise_error(U2F::RegistrationError) do |error|
        expect(error.code).to eq(4)
      end
    end
  end

  context 'with unpadded response' do
    let(:registration_data_json) { registration_data_json_without_padding }
    it 'does not raise "invalid base64" exception' do
      expect {
        register_response
      }.not_to raise_error
    end
  end

  describe '#certificate' do
    subject { register_response.certificate }
    it { is_expected.to eq certificate }
  end

  describe '#client_data' do
    context 'challenge' do
      subject { register_response.client_data.challenge }
      it { is_expected.to eq challenge }
    end
  end

  describe '#key_handle' do
    subject { register_response.key_handle }
    it { is_expected.to eq key_handle }
  end

  describe '#key_handle_length' do
    subject { register_response.key_handle_length }
    it { is_expected.to eq U2F.urlsafe_decode64(key_handle).length }
  end

  describe '#public_key' do
    subject { register_response.public_key }
    it { is_expected.to eq public_key }
  end

  describe '#verify' do
    subject { register_response.verify(app_id) }
    it { is_expected.to be_truthy }
  end

  describe '#verify with wrong app_id' do
    subject { register_response.verify("other app") }
    it { is_expected.to be_falsey }
  end

  describe '#verify with corrupted signature' do
    subject { register_response }
    it "returns falsey" do
      allow(subject).to receive(:signature).and_return("bad signature")
      expect(subject.verify(app_id)).to be_falsey
    end
  end
end
