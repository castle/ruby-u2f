module U2FExample
  class App < Padrino::Application
    register Padrino::Helpers
    enable :sessions

    get "/" do
      redirect url(:registrations, :new)
    end
  end
end
