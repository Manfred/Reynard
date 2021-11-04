# Reynard

Reynard is an OpenAPI client for Ruby. It operates directly on the OpenAPI specification without the need to generate any source code.

```ruby
# A Client does not have a fixed state and creating a new
# client will never incur a cost over creating the object
# itself.
reynard = Reynard.new(filename: 'openapi.yml')
```

## Installing

Reynard is distributed as a gem called `reynard`.

## Choosing a server

An OpenAPI specification may specify multiple servers. There is no automated way to select the ‘correct’ server so Reynard uses the first one by default.

For example:

```yaml
servers:
  - url: http://production.example.com/v1
  - url: http://staging.example.com/v1
```

Will cause Reynard to choose the production URL.

```ruby
reynard.url #=> "http://production.example.com/v1"
```

You can override the `base_url` if you want to use a different one.

```ruby
reynard.base_url('http://test.example.com/v1')
```

You also have access to all servers in the specification so you can automatically select one however you want.

```ruby
base_url = @reynard.servers.map(&:url).find do |url|
  /staging/.match(url)
end
reynard.base_url(base_url)
```

## Calling endpoints

Assuming there is an operation called `employeeByUuid` you can it as shown below.

```ruby
employee = reynard.
  operation('employeeByUuid').
  params(uuid: uuid).
  execute
```

When an operation requires a body, you can add it as structured data.

```ruby
employee = reynard.
  operation('createEmployee').
  body(name: 'Sam Seven').
  execute
```

## Mocking

You can mock Reynard requests by changing the HTTP implementation. The class **must** implement a single `request` method that accepts an URI and net/http request object. It **must** return a net/http response object or an object with the exact same interface.

```ruby
Reynard.http = MyMock.new

class MyMock
  def request(uri, net_http_request)
    Net::HTTPResponse::CODE_TO_OBJ['404'].new('HTTP/1.1', '200', 'OK')
  end
end
```

## Copyright and other legal

See LICENCE.