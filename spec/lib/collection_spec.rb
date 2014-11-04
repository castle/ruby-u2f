require 'spec_helper'

describe U2F::Collection do
  let(:collection) { U2F::Collection.new(input) }
  describe '#to_json' do
    subject { collection.to_json }
    context 'with single object' do
      let(:input) { 'one' }
      it do
        is_expected.to match_json_expression(['one'])
      end
    end
    context 'with single object' do
      let(:input) { ['one', 'two'] }
      it do
        is_expected.to match_json_expression(['one', 'two'])
      end
    end
  end
end
