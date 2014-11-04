class Registration
  include DataMapper::Resource

  # property <name>, <type>
  property :id, Serial
  property :key_handle, String
  property :public_key, String
  property :certificate, Text
  property :counter, Integer
end
