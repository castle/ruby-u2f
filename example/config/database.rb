DataMapper.logger = logger
DataMapper::Property::String.length(255)
DataMapper.setup(:default, 'sqlite3://' + Padrino.root('db', 'u2f_example.db'))
