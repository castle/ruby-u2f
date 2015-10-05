require 'spec_helper.rb'

describe U2F::SignResponse do
  let(:app_id) { 'http://demo.example.com' }
  let(:challenge) { U2F.urlsafe_encode64(SecureRandom.random_bytes(32)) }
  let(:device) { U2F::FakeU2F.new(app_id) }
  let(:json_response) { device.sign_response(challenge) }
  let(:sign_response) { U2F::SignResponse.load_from_json json_response }
  let(:public_key_pem) { U2F::U2F.public_key_pem(device.origin_public_key_raw) }

  describe '#counter' do
    subject { sign_response.counter }
    it { is_expected.to be device.counter }
  end

  describe '#user_present?' do
    subject { sign_response.user_present? }
    it { is_expected.to be true }
  end

  describe '#verify with correct app id' do
    subject { sign_response.verify(app_id, public_key_pem) }
    it { is_expected.to be_truthy}
  end

  describe '#verify with wrong app id' do
    subject { sign_response.verify("other app", public_key_pem) }
    it { is_expected.to be_falsey }
  end

  describe '#verify with corrupted signature' do
    subject { sign_response }
    it "returns falsey" do
      allow(subject).to receive(:signature).and_return("bad signature")
      expect(subject.verify(app_id, public_key_pem)).to be_falsey
    end
  end
end
