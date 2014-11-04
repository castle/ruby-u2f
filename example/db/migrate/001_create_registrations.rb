migration 1, :create_registrations do
  up do
    create_table :registrations do
      column :id, Integer, :serial => true
      column :key_handle, DataMapper::Property::String, :length => 255
      column :public_key, DataMapper::Property::String, :length => 255
      column :certificate, DataMapper::Property::Text
      column :counter, DataMapper::Property::Integer
    end
  end

  down do
    drop_table :registrations
  end
end
