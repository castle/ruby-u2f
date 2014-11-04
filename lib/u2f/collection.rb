module U2F
  class Collection < Array
    def initialize(array)
      super([*array])
    end

    def to_json
      "[#{map { |a| a.to_json }.join(',')}]"
    end
  end
end
