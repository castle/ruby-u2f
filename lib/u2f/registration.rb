module U2F
  ##
  # A representation of a registered U2F device
  class Registration
    attr_accessor :key_handle, :public_key, :certificate, :counter
    def initialize(key_handle, public_key, certificate)
      @key_handle = key_handle
      @public_key = public_key
      @certificate = certificate
    end

    def counter
      @counter.nil? ? 0 : @counter
    end
  end
end