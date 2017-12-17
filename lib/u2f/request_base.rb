# frozen_string_literal: true

module U2F
  module RequestBase
    def to_json(options = {})
      ::JSON.pretty_generate(as_json, options)
    end

    def version
      'U2F_V2'
    end
  end
end
