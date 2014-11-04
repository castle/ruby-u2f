Padrino.configure_apps do
  set :session_secret, '723c1901f2645a2f8c1bacb955f9da81346bf5a8200a4498'
  set :protection, except: :path_traversal
  set :protect_from_csrf, true
end

Padrino.mount('U2FExample::App', app_file: Padrino.root('app/app.rb')).to('/')
