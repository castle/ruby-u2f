# Ruby U2F

[![Gem Version](https://badge.fury.io/rb/u2f.png)](http://badge.fury.io/rb/u2f)
[![Dependency Status](https://gemnasium.com/castle/ruby-u2f.svg)](https://gemnasium.com/castle/ruby-u2f)
[![security](https://hakiri.io/github/castle/ruby-u2f/master.svg)](https://hakiri.io/github/castle/ruby-u2f/master)

[![Build Status](https://travis-ci.org/castle/ruby-u2f.png)](https://travis-ci.org/castle/ruby-u2f)
[![Code Climate](https://codeclimate.com/github/castle/ruby-u2f/badges/gpa.svg)](https://codeclimate.com/github/castle/ruby-u2f)
[![Coverage Status](https://img.shields.io/coveralls/castle/ruby-u2f.svg)](https://coveralls.io/r/castle/ruby-u2f)

Provides functionality for working with the server side aspects of the U2F
protocol as defined in the [FIDO specifications](http://fidoalliance.org/specifications/download). To read more about U2F and how to use a U2F library, visit [developers.yubico.com/U2F](http://developers.yubico.com/U2F).

## What is U2F?

U2F is an open 2-factor authentication standard that enables keychain devices, mobile phones and other devices to securely access any number of web-based services — instantly and with no drivers or client software needed. The U2F specifications were initially developed by Google, with contribution from Yubico and NXP, and are today hosted by the [FIDO Alliance](https://fidoalliance.org/).

## Working example application

Check out the [example](https://github.com/castle/ruby-u2f/tree/master/example) directory for a fully working Padrino server demonstrating U2F.

There is another demo application available using the [Cuba](https://github.com/soveran/cuba) framework: [cuba-u2f-demo](https://github.com/badboy/cuba-u2f-demo) and a [blog post explaining the protocol and the implementation](http://fnordig.de/2015/03/06/u2f-demo-application/).

You'll need Google Chrome 41 or later to use U2F.

## Installation

Add the `u2f` gem to your `Gemfile`

```ruby
gem 'u2f'
```

## Usage

The U2F library has two major tasks:

- **Register** new devices.
- **Authenticate** previously registered devices.

Each task starts by generating a challenge on the server, which is rendered to a web view, read by the browser APIs and transmitted to the plugged in U2F devices for verification. The U2F device responds and triggers a callback in the browser, and a form is posted back to your server where you verify the challenge and store the U2F device information to your database.

You'll need an instance of `U2F::U2F`, which is conveniently placed in an [instance method](https://github.com/castle/ruby-u2f/blob/master/example/app/helpers/helpers.rb) on the controller. The initializer takes an **App ID** as argument.

```ruby
def u2f
  @u2f ||= U2F::U2F.new(request.base_url)
end
```

**Important:** A U2F client (e.g. Chrome) will compare the App ID with the current URI, so make sure it's the right format including schema and port, e.g. `https://demo.example.com:3000`. Check out the [App ID specification](https://developers.yubico.com/U2F/App_ID.html) for more details.

### Registration

Generate the requests which will be sent to the U2F device.

```ruby
# registrations_controller.rb
def new
  # Generate one for each version of U2F, currently only `U2F_V2`
  @registration_requests = u2f.registration_requests

  # Store challenges. We need them for the verification step
  session[:challenges] = @registration_requests.map(&:challenge)

  # Fetch existing Registrations from your db and generate SignRequests
  key_handles = Registration.map(&:key_handle)
  @sign_requests = u2f.authentication_requests(key_handles)

  render 'registrations/new'
end
```

Render a form that will be automatically posted when the U2F device reponds.

```html
<!-- registrations/new.html -->
<form action="/registrations" method="post">
  <input type="hidden" name="response">
</form>
```

```javascript
// render requests from server into Javascript format
var registerRequests = <%= @registration_requests.as_json.to_json.html_safe %>;
var signRequests = <%= @sign_requests.as_json.to_json.html_safe %>;

u2f.register(registerRequests, signRequests, function(registerResponse) {
  var form, reg;

  if (registerResponse.errorCode) {
    return alert("Registration error: " + registerResponse.errorCode);
  }

  form = document.forms[0];
  response = document.querySelector('[name=response]');

  response.value = JSON.stringify(registerResponse);

  form.submit();
});
```

Catch the response on your server, verify it, and store a reference to it in your database.

```ruby
# registrations_controller.rb
def create
  response = U2F::RegisterResponse.load_from_json(params[:response])

  reg = begin
    u2f.register!(session[:challenges], response)
  rescue U2F::Error => e
    return "Unable to register: <%= e.class.name %>"
  ensure
    session.delete(:challenges)
  end

  # save a reference to your database
  Registration.create!(certificate: reg.certificate,
                       key_handle:  reg.key_handle,
                       public_key:  reg.public_key,
                       counter:     reg.counter)

  'Registered!'
end
```

### Authentication

Generate the requests which will be sent to the U2F device.

```ruby
# authentications_controller.rb
def new
  # Fetch existing Registrations from your db
  key_handles = Registration.map(&:key_handle)
  return 'Need to register first' if key_handles.empty?

  # Generate SignRequests
  @sign_requests = u2f.authentication_requests(key_handles)

  # Store challenges. We need them for the verification step
  session[:challenges] = @sign_requests.map(&:challenge)

  render 'authentications/new'
end
```

Render a form that will be automatically posted when the U2F device reponds.

```html
<!-- registrations/new.html -->
<form action="/authentications" method="post">
  <input type="hidden" name="response">
</form>
```

```javascript
// render requests from server into Javascript format
var signRequests = <%= @sign_requests.as_json.to_json.html_safe %>;

u2f.sign(signRequests, function(signResponse) {
  var form, reg;

  if (signResponse.errorCode) {
    return alert("Authentication error: " + signResponse.errorCode);
  }

  form = document.forms[0];
  response = document.querySelector('[name=response]');

  response.value = JSON.stringify(signResponse);

  form.submit();
});
```

Catch the response on your server, verify it, and bump the counter in your database reference.

```ruby
# authentications_controller.rb
def create
  response = U2F::SignResponse.load_from_json(params[:response])

  registration = Registration.first(key_handle: response.key_handle)
  return 'Need to register first' unless registration

  begin
    u2f.authenticate!(session[:challenges], response,
                      Base64.decode64(registration.public_key),
                      registration.counter)
  rescue U2F::Error => e
    return "Unable to authenticate: <%= e.class.name %>"
  ensure
    session.delete(:challenges)
  end

  registration.update(counter: response.counter)

  'Authenticated!'
end
```

## License

MIT License. Copyright (c) 2015 by Johan Brissmyr and Sebastian Wallin
