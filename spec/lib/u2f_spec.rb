require 'spec_helper'

describe U2F do
  let(:app_id) { 'http://demo.example.com' }
  let(:u2f) { U2F::U2F.new(app_id) }
  let(:challenge) { 'fEnc9oV79EaBgK5BoNERU5gPKM2XGYWrz4fUjgc0Q7g' }
  let(:key_handle) do
    'CTUayZo8hCBeC-sGQJChC0wW-bBg99bmOlGCgw8XGq4dLsxO3yWh9mRYArZxocP5hBB1pEGB3bbJYiM-5acc5w'
  end
  let(:certificate) do
    "MIIC4jCBywIBATANBgkqhkiG9w0BAQsFADAdMRswGQYDVQQDExJZdWJpY28gVTJGIFRlc3QgQ0EwHhcNMTQwNTE1MTI1ODU0WhcNMTQwNjE0MTI1ODU0WjAdMRswGQYDVQQDExJZdWJpY28gVTJGIFRlc3QgRUUwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATbCtv1IcdczmPcpuHoJQYNlOYnVBlPnSSvJhq+rZlEH5WjcZEKOiDnPpFeE+i+OAV61XqjfnaQj6\/iipS2MOudMA0GCSqGSIb3DQEBCwUAA4ICAQCVQGtQYX2thKO064gP4zAPLaIKANklBO5y+mffWFEPC0cCnD5BKUqTrCmFiS2keoEyKFdxAe+oQogWljeR1d\/gj8k8jbDNiXCC7HnTxnhzKTLlq2y9Vp\/VRZHOwd2NZNzpnB9ePNKvUaWCGK\/gN+cynnYFdwJ75iSgMVYb\/RnFcdPwnsBzBU68hbhTnu\/FvJxWo7rZJ2q7qXpA10eLVXJr4\/4oSXEk9I\/0IIHqOP98Ck\/fAoI5gYI7ygndyqoPJ\/Wkg1VsmjmbFToWY9xb+axbvPefvg+KojwxE6MySMpYh\/h7oKEKamCWk19dJp5jHQmumkHlvQhH\/uUJmyD9EuLmQH+6SmEzZg0Oc9uw1aKamhcNNDCFakJGnv80j1+HbDXnqE0168FBqorS2hmqeaJfNSyg\/SXT950lGC36tLy7BzQ8jYG99Ok32znp0UVbIEEvLSci3JJ0ipLVg\/0J+xOb4zl6a1z65nae4OTj7628\/UJFmtSU0X6Np9gF1dNizxXPlH0fW1ggRCCQcb5m6ZqrdDJwUx1p7Ydm9AlPyiUwwmN5ADyxmzk\/AOCoiO96UVvnvUlk2kF7JMNxIv3R0SCzP5fTl7KqGByeA3d7W375o6DWIIEsOI+dJd7pyPXdakecZQRaVubC6\/ICl+G52OEkdp8jYjkDS8j3NAdJ1udNmg=="
  end
  let(:public_key) do
    Base64.urlsafe_decode64("BC0SaFZWC9uH7wamOwduP93kUH2I2hEvyY0Srfj4A258pZSlV0iPoFIH+bd4yhncaqdoPLdEDl5Y\/yaFORPUe3c=")
  end
  let(:json_response) do
    '{ "signatureData": "AQAAAAQwRQIhAI6FSrMD3KUUtkpiP0jpIEakql-HNhwWFngyw553pS1CAiAKLjACPOhxzZXuZsVO8im-HStEcYGC50PKhsGp_SUAng==", "clientData": "eyAiY2hhbGxlbmdlIjogImZFbmM5b1Y3OUVhQmdLNUJvTkVSVTVnUEtNMlhHWVdyejRmVWpnYzBRN2ciLCAib3JpZ2luIjogImh0dHA6XC9cL2RlbW8uZXhhbXBsZS5jb20iLCAidHlwIjogIm5hdmlnYXRvci5pZC5nZXRBc3NlcnRpb24iIH0=", "keyHandle": "CTUayZo8hCBeC-sGQJChC0wW-bBg99bmOlGCgw8XGq4dLsxO3yWh9mRYArZxocP5hBB1pEGB3bbJYiM-5acc5w" }'
  end
  let(:response) do
    U2F::SignResponse.create_from_json json_response
  end
  let(:registration) do
    U2F::Registration.new(key_handle, public_key, certificate)
  end
  let(:sign_request) do
    U2F::SignRequest.new(key_handle, challenge, app_id)
  end

  describe '::new' do
    it 'initializes' do
      u2f
    end
  end

  describe '#authenticate!' do
    context 'with correct SignRequest' do
      it 'returns an updated Registration' do
        reg = u2f.authenticate!(sign_request, registration, response)
        expect(reg).to be_truthy
        expect(reg.counter).to be 4
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

    context 'with incorrect key' do
      let(:public_key) { Base64.urlsafe_decode64('NW5jdzdnODV3dm9nNzU4d2duNTd3') }
      it 'fails when key is to short' do
        expect {
          U2F::U2F.public_key_pem public_key
        }.to raise_error(U2F::PublicKeyDecodeError)
      end
    end
  end
end