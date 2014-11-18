module U2FExample
  class App < Padrino::Application
    register Padrino::Helpers
    enable :sessions

    get "/" do
      render 'index'
    end
  end
end
