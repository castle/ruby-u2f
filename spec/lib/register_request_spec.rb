require 'spec_helper'

describe U2F::RegisterRequest do
  let(:challenge) { 'fEnc9oV79EaBgK5BoNERU5gPKM2XGYWrz4fUjgc0Q7g' }

  let(:sign_request) do
    U2F::RegisterRequest.new(challenge)
  end

  describe '#to_json' do
    subject { sign_request.to_json }
    it do
      is_expected.to match_json_expression(
        version: String,
        challenge: String
      )
    end
  end
end
