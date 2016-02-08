require 'spec_helper'

describe U2F::SignRequest do
  let(:key_handle) do
    'CTUayZo8hCBeC-sGQJChC0wW-bBg99bmOlGCgw8XGq4dLsxO3yWh9mRYArZxocP5hBB1pEGB3bbJYiM-5acc5w=='
  end
  let(:sign_request) do
    U2F::SignRequest.new(key_handle)
  end

  describe '#to_json' do
    subject { sign_request.to_json }
    it do
      is_expected.to match_json_expression(
        version: String,
        keyHandle: String
      )
    end
  end
end
