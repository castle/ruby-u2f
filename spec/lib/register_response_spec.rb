require 'spec_helper.rb'

describe U2F::RegisterResponse do
  let(:key_handle) do
    'CTUayZo8hCBeC-sGQJChC0wW-bBg99bmOlGCgw8XGq4dLsxO3yWh9mRYArZxocP5hBB1pEGB3bbJYiM-5acc5w=='
  end
  let(:public_key) do
    'BC0SaFZWC9uH7wamOwduP93kUH2I2hEvyY0Srfj4A258pZSlV0iPoFIH+bd4yhncaqdoPLdEDl5Y/yaFORPUe3c='
  end
  let(:certificate) do
    'MIIC4jCBywIBATANBgkqhkiG9w0BAQsFADAdMRswGQYDVQQDExJZdWJpY28gVTJGIFRlc3QgQ0EwHhcNMTQwNTE1MTI1ODU0WhcNMTQwNjE0MTI1ODU0WjAdMRswGQYDVQQDExJZdWJpY28gVTJGIFRlc3QgRUUwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATbCtv1IcdczmPcpuHoJQYNlOYnVBlPnSSvJhq+rZlEH5WjcZEKOiDnPpFeE+i+OAV61XqjfnaQj6/iipS2MOudMA0GCSqGSIb3DQEBCwUAA4ICAQCVQGtQYX2thKO064gP4zAPLaIKANklBO5y+mffWFEPC0cCnD5BKUqTrCmFiS2keoEyKFdxAe+oQogWljeR1d/gj8k8jbDNiXCC7HnTxnhzKTLlq2y9Vp/VRZHOwd2NZNzpnB9ePNKvUaWCGK/gN+cynnYFdwJ75iSgMVYb/RnFcdPwnsBzBU68hbhTnu/FvJxWo7rZJ2q7qXpA10eLVXJr4/4oSXEk9I/0IIHqOP98Ck/fAoI5gYI7ygndyqoPJ/Wkg1VsmjmbFToWY9xb+axbvPefvg+KojwxE6MySMpYh/h7oKEKamCWk19dJp5jHQmumkHlvQhH/uUJmyD9EuLmQH+6SmEzZg0Oc9uw1aKamhcNNDCFakJGnv80j1+HbDXnqE0168FBqorS2hmqeaJfNSyg/SXT950lGC36tLy7BzQ8jYG99Ok32znp0UVbIEEvLSci3JJ0ipLVg/0J+xOb4zl6a1z65nae4OTj7628/UJFmtSU0X6Np9gF1dNizxXPlH0fW1ggRCCQcb5m6ZqrdDJwUx1p7Ydm9AlPyiUwwmN5ADyxmzk/AOCoiO96UVvnvUlk2kF7JMNxIv3R0SCzP5fTl7KqGByeA3d7W375o6DWIIEsOI+dJd7pyPXdakecZQRaVubC6/ICl+G52OEkdp8jYjkDS8j3NAdJ1udNmg=='
  end
  let(:registration_data_json) do
    '{ "registrationData": "BQQtEmhWVgvbh-8GpjsHbj_d5FB9iNoRL8mNEq34-ANufKWUpVdIj6BSB_m3eMoZ3GqnaDy3RA5eWP8mhTkT1Ht3QAk1GsmaPIQgXgvrBkCQoQtMFvmwYPfW5jpRgoMPFxquHS7MTt8lofZkWAK2caHD-YQQdaRBgd22yWIjPuWnHOcwggLiMIHLAgEBMA0GCSqGSIb3DQEBCwUAMB0xGzAZBgNVBAMTEll1YmljbyBVMkYgVGVzdCBDQTAeFw0xNDA1MTUxMjU4NTRaFw0xNDA2MTQxMjU4NTRaMB0xGzAZBgNVBAMTEll1YmljbyBVMkYgVGVzdCBFRTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABNsK2_Uhx1zOY9ym4eglBg2U5idUGU-dJK8mGr6tmUQflaNxkQo6IOc-kV4T6L44BXrVeqN-dpCPr-KKlLYw650wDQYJKoZIhvcNAQELBQADggIBAJVAa1Bhfa2Eo7TriA_jMA8togoA2SUE7nL6Z99YUQ8LRwKcPkEpSpOsKYWJLaR6gTIoV3EB76hCiBaWN5HV3-CPyTyNsM2JcILsedPGeHMpMuWrbL1Wn9VFkc7B3Y1k3OmcH1480q9RpYIYr-A35zKedgV3AnvmJKAxVhv9GcVx0_CewHMFTryFuFOe78W8nFajutknarupekDXR4tVcmvj_ihJcST0j_Qggeo4_3wKT98CgjmBgjvKCd3Kqg8n9aSDVWyaOZsVOhZj3Fv5rFu895--D4qiPDETozJIyliH-HugoQpqYJaTX10mnmMdCa6aQeW9CEf-5QmbIP0S4uZAf7pKYTNmDQ5z27DVopqaFw00MIVqQkae_zSPX4dsNeeoTTXrwUGqitLaGap5ol81LKD9JdP3nSUYLfq0vLsHNDyNgb306TfbOenRRVsgQS8tJyLcknSKktWD_Qn7E5vjOXprXPrmdp7g5OPvrbz9QkWa1JTRfo2n2AXV02LPFc-UfR9bWCBEIJBxvmbpmqt0MnBTHWnth2b0CU_KJTDCY3kAPLGbOT8A4KiI73pRW-e9SWTaQXskw3Ei_dHRILM_l9OXsqoYHJ4Dd3tbfvmjoNYggSw4j50l3unI9d1qR5xlBFpW5sLr8gKX4bnY4SR2nyNiOQNLyPc0B0nW502aMEUCIQDTGOX-i_QrffJDY8XvKbPwMuBVrOSO-ayvTnWs_WSuDQIgZ7fMAvD_Ezyy5jg6fQeuOkoJi8V2naCtzV-HTly8Nww=", "clientData": "eyAiY2hhbGxlbmdlIjogInlLQTB4MDc1dGpKLUdFN2ZLVGZuelRPU2FOVU9XUXhSZDlUV3o1YUZPZzgiLCAib3JpZ2luIjogImh0dHA6XC9cL2RlbW8uZXhhbXBsZS5jb20iLCAidHlwIjogIm5hdmlnYXRvci5pZC5maW5pc2hFbnJvbGxtZW50IiB9" }'
  end

  let(:registration_data_without_padding) {
    "{\"registrationData\":\"BQT2UXxw7PXHmN5nCj1M3Lq_sibfqQehZbuUV1Vxr1l0J1Gdcv7FEvnPofmrSN44_pz8-XAj7pOpqB79rOphJPf2QM8nt8Jtyyj9_XmZWZTQMg2UVHvrin_Jc4tMHY9QmyCNDmSU9_Bhb-Ei4u5GPgLrpF1TaEYQCqUHboqDKt4x524wggIbMIIBBaADAgECAgR1o_Z1MAsGCSqGSIb3DQEBCzAuMSwwKgYDVQQDEyNZdWJpY28gVTJGIFJvb3QgQ0EgU2VyaWFsIDQ1NzIwMDYzMTAgFw0xNDA4MDEwMDAwMDBaGA8yMDUwMDkwNDAwMDAwMFowKjEoMCYGA1UEAwwfWXViaWNvIFUyRiBFRSBTZXJpYWwgMTk3MzY3OTczMzBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABBmjfkNqa2mXzVh2ZxuES5coCvvENxDMDLmfd-0ACG0Fu7wR4ZTjKd9KAuidySpfona5csGmlM0Te_Zu35h_wwujEjAQMA4GCisGAQQBgsQKAQIEADALBgkqhkiG9w0BAQsDggEBAb0tuI0-CzSxBg4cAlyD6UyT4cKyJZGVhWdtPgj_mWepT3Tu9jXtdgA5F3jfZtTc2eGxuS-PPvqRAkZd40AXgM8A0YaXPwlT4s0RUTY9Y8aAQzQZeAHuZk3lKKd_LUCg5077dzdt90lC5eVTEduj6cOnHEqnOr2Cv75FuiQXX7QkGQxtoD-otgvhZ2Fjk29o7Iy9ik7ewHGXOfoVw_ruGWi0YfXBTuqEJ6H666vvMN4BZWHtzhC0k5ceQslB9Xdntky-GQgDqNkkBf32GKwAFT9JJrkO2BfsB-wfBrTiHr0AABYNTNKTceA5dtR3UVpI492VUWQbY3YmWUUfKTI7fM4wRgIhAIfEKaF0w43L3RJHXp8qeRKw8Ek0CVcZ6pvBsH3Wo3F1AiEA5w89AFOBrjoSsnuGdUgB4AGxc5bRnV-p8jGUNoVSUwI\",\"version\":\"U2F_V2\",\"challenge\":\"oqDO4u_tTvhm1LhFDVYhFwywQF0PzFsXPgjD-5lKGDY=\",\"appId\":\"http://localhost:3000\",\"clientData\":\"eyJ0eXAiOiJuYXZpZ2F0b3IuaWQuZmluaXNoRW5yb2xsbWVudCIsImNoYWxsZW5nZSI6Im9xRE80dV90VHZobTFMaEZEVlloRnd5d1FGMFB6RnNYUGdqRC01bEtHRFk9Iiwib3JpZ2luIjoiaHR0cDovL2xvY2FsaG9zdDozMDAwIiwiY2lkX3B1YmtleSI6IiJ9\"}"
  }

  let(:app_id) { 'http://demo.example.com' }
  let(:challenge) { 'yKA0x075tjJ-GE7fKTfnzTOSaNUOWQxRd9TWz5aFOg8' }

  let(:registration_request) { U2F::RegisterRequest.new(challenge, app_id) }

  let(:register_response) do
    U2F::RegisterResponse.load_from_json(registration_data_json)
  end

  context 'with unpadded response' do
    let(:registration_data_json) { registration_data_without_padding }
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
end