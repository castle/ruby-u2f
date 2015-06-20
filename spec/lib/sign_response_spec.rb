require 'spec_helper.rb'

describe U2F::SignResponse do
  let(:app_id) { 'http://demo.example.com' }
  let(:challenge) { U2F.urlsafe_encode64(SecureRandom.random_bytes(32)) }
  let(:device) { U2F::FakeU2F.new(app_id) }
  let(:json_response) { device.sign_response(challenge) }
  let(:sign_response) { U2F::SignResponse.load_from_json json_response }

  describe '#counter' do
    subject { sign_response.counter }
    it { is_expected.to be device.counter }
  end

  describe '#user_present?' do
    subject { sign_response.user_present? }
    it { is_expected.to be true }
  end
end
