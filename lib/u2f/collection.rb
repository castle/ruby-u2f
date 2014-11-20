module U2F
  ##
  # Extension of +Array+ which implements a +to_json+ serializer
  class Collection < Array
    def initialize(array)
      super([*array])
    end

    def to_json
      "[#{map { |a| a.to_json }.join(',')}]"
    end
  end
end
