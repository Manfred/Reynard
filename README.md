# Reynard

Reynard is an OpenAPI client for Ruby. It operates directly on the OpenAPI specification without the need to generate any source code.

```ruby
# Reynard does not have a global state and there is no cost to creating a new
# client instance other than building a new object.
reynard = Reynard.new(filename: 'openapi.yml')
```

## Installing

Reynard is distributed as a gem called `reynard`.

## Choosing a server

An OpenAPI specification may specify multiple servers. There is no automated way to select the ‘correct’ server so Reynard uses the first one by default.

For example, given a specification with the following servers:

```yaml
servers:
  - url: http://production.example.com/v1
  - url: http://staging.example.com/v1
```

Reynard will choose the first server item.

```ruby
reynard.url #=> "http://production.example.com/v1"
```

You can override this `base_url` to any value, even one that is not listed in the specification.

```ruby
reynard.base_url('http://test.example.com/v1')
```

You also have access to all servers in the specification so you can use them to automatically pick a supported URL.

```ruby
base_url = reynard.servers.map(&:url).find do |url|
  /staging/.match(url)
end
reynard.base_url(base_url)
```

## Executing an operation

You perform an operation by initializing it using its `operationId` from the specification.

```ruby
response = reynard.
  operation('employeeByUuid').
  params({ 'uuid' =>  uuid }).
  execute
```

Note that the `operationId` is specifically designed to be used this way, it is required and unique within every OpenAPI specification.

When an operation requires parameters in the body, you can add them as structured data.

```ruby
response = reynard.
  operation('createEmployee').
  body({ 'name' => 'Sam Seven'}).
  execute
```

The response object shares much of its interface with `Net::HTTP::Response`.

```ruby
response.code #=> '200'
response.content_type #=> 'application/json'
response['Content-Type'] #=> 'application/json'
response.body #=> '{"name":"Sam Seven"}'
response.parsed_body #=> { "name" => "Sam Seven" }
```

You can test for groups of response codes, basically matching `1xx` through `5xx`.

```ruby
response.informational?
response.success?
response.redirection?
response.client_error?
response.server_error?
```

In case the response status and content-type matches a response defined in the specification it will attempt to build an object using the specified schema.

```ruby
response.object.name #=> 'Sam Seven'
```

Most of this behavior can be extended or configured to suit the demands of the application. See below for more details.

## Building a request

One of the design principles of Reynard is that makes a copy of its state on every method call. You generally start building a request by calling `operation` on the specification object.

```ruby
request = reynard.operation('createEmployee')
```

Parameters provided through the `params` method automatically end in the query, headers, request path, or cookies in accordance with the OpenAPI specs. Calling the method multiple times will merge new parameters with existing ones.

```ruby
request = request.params({ 'cache' => 'false' }}
```

You can add custom headers to the request using the `headers` method. Reynard will allow you to add headers that are not part of the specification and also doesn't warn when you overwrite headers defined in the parameters specification.

```ruby
request = request.headers({ 'User-Agent' => "MyApplication/12.1.1 #{Reynard.user_agent}" )
```

Parameters or data for the request body are separate and are supplied using the `body` method.

```ruby
request = request.body({ 'name' => 'Carly Eye' })
```

Reynard will choose the first supported content-type in the request body content specification and use it to serialize the data. There are a number of built-in serializers, and you can register your own to replace existing ones or add new ones.

```ruby
request = request.serializer(
  "application/json",
  Reynard::Serializers::ApplicationJson
)
```

The initializer of the supplied class must take a `data:` argument in its initializer and respond to `mime_type`, `headers`, and `body`.

You can remove serializers by setting them to nil.

```ruby
reynard.serializer("application/json", nil)
```

When none of the request body content specifications are supported, you can expect an exception.

Note that some serializers may require the data to be a different type. For example, the `text/plain` serializer requires a `String`.

```ruby
request = request.body("Hello Fox!")
```

Reynard currently ignores the request schema in the specification so you are responsible for providing a correct payload.

## Executing the request

Reynard gathers details in a request context and doesn't start serializing and actually performing the request until you call `execute`. It builds a `Net::HTTP` request object and hands it off the HTTP client.

```ruby
Reynard.http.request(uri, net_http_request)
```

See below on how you can use this to mock Reynard responses.

## Dealing with a response

A Reynard response shares much of its interface with `Net::HTTP::Response` because it delegates the following methods to the response object:

- `code`
- `content_type`
- `[]`
- `body`

As previously discussed there are a few convenience methods like `success?` to interpret the response code classes.

The biggest extension is that you can get a parsed body and usually also a model instance based on the schema in the specification.

### Parsed body

You can get the parsed body from the response by calling the `parsed_body` method. Reynard doesn't touch the response body until you actually call this method.

```ruby
response.parsed_body #=> { 'name' => 'Carly Eye' }
```

Reynard chooses a response body deserializer based on the response content-type, meaning it can also provide a parsed response when it doesn't follow the specification. There are a number of built-in deserializers, and you can register your own to replace existing ones or add new ones.

```ruby
request = request.deserializer(
  "application/json",
  Reynard::Deserializers::ApplicationJson
)
```

The initializer of the supplied class must take `headers:` and `body:` arguments in its initializer and respond to a `call` method.

You can remove deserializers by setting them to nil.

```ruby
reynard.deserializer("application/json", nil)
```

When the response content-type does not have a matching deserializer, you can expect an exception.

Note that some deserializers may return different types, like the deserializer for `text/plain`.

### Schemas and models

Reynard has a model and object builder that allows you to get a value object backed by model classes based on the resource schema. You get a model instance by calling the `object` method on the response. Reynard doesn't do anything related to schemas and models until you call this method.

```ruby
# When using humanized model naming you get a Ruby class instance.
response.object.class #=> Reynard::Models::Employee
```

These models have accessor methods for each property returned in the response, even when it doesn't follow the response schema.

Requirements for how response objects are built vary so there is some extensibility here. Reynard uses the following settings by default:

```ruby
reynard.property_naming(Reynard::Naming::PropertyNaming.new)
reynard.model_naming(Reynard::Naming::ModelNaming.new)
reynard.model_registry(Reynard::Naming::ModelRegistry.new)
```

We'll explain the defaults first and then why you may have to change these classes or their configuration.

#### Access to model properties

A Reynard model instance will have an accessor for every property supplied in the response object. For example, when the response is something like this:

```
Content-Type: application/json

{"title":"Erebus","author":{"name":"Palin"}}
```

The model will give access to both properties and also to properties of nested objects:

```ruby
response.object.title #=> 'Erebus'
response.object.author.name #=> 'Palin'
```

Models also support the `[]` method, meaning you can do this:

```ruby
response.object['title'] #=> 'Erebus'
response.object['author']['name'] #=> 'Palin'
```

It's more efficient to use `parsed_body` in this case, but there are two good reasons to use `[]`:

1. When you pass the response object into other code that may need both access methods.
2. When the property name can't be transformed to a valid Ruby method name.
3. When you are no sure the property will be in the response data.

Finally you can use `try` on the model in case you are not sure if a property is returned at all. This is useful when you are in the middle of a schema migration. Calling `try` prevents a `NoMethodError` when the property doesn't exist.

```ruby
response.object.try(:isbn) #=> nil
```

Don't use `send` to access the property, this is not supported. Using either `[]` or `try` may mask typos and other bugs, so use them with caution.

#### Model property naming

Default property naming in Reynard transforms property names to snake-case before defining them as an accessor. For example, when the response is something like this:

```
Content-Type: application/json

{"first_name":"Marcél","lastName":"Marcellus","1st-class":false}
```

You can access the name through accessors like this:

```ruby
response.object.first_name #=> "Marcél"
response.object.last_name #=> "Marcellus"
```

However, a method can't start with a number and can't contain dashes in Ruby so the following is not possible:

```
# Not valid Ruby syntax:
response.object.1st-class
```

In case you are forced to access a property through a method, you could choose to map irregular property names to method names like this:

```ruby
naming = Reynard::Naming::PropertyNaming.new(
  exceptions: {
		"1st-class" => "first_class"
	}
)
response =
  reynard
  .property_naming(naming)
  .operation('getEmployee')
  .params({ 'id' => 42 })
  .execute
response.object.first_class #=> false
```

Note that models may be cached in a global registry so changing property naming late may lead to unexpected results.

A custom property naming object should respond to a `call` method that takes a single `String` argument, for example:

```ruby
class UpcasePropertyNaming
  def call(name)
    name.upcase
  end
end

reynard.property_naming(UpcasePropertyNaming.new)
```

Or the same thing as a Proc:

```ruby
reynard.property_naming(->(name) { name.upcase })
```

#### Model naming

Default model naming in Reynard uses details from the specification to come up with a name that is also a valid Ruby constant name. The model name is determined in the following order:

1. From the `title` property in the content schema
2. From the `$ref` in the content schema
3. From the request path in the operation

For example, with a specification like this:

```yaml
/item/{id}:
  get:
    responses:
      "200":
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/Book"
components:
  schemas:
    Book:
      type: object
      title: LibraryBook
```

- Step 1 produces `LibraryBook` from the `title` attribute
- Step 2 produces `Book` from `#/components/schemas/Book`
- Step 3 produces `items` from `/items/{id}`.

The model name is then normalized and upcased so it becomes a valid Ruby constant name.

This process may produce bad names or duplicate names and that may introduce problems with certain model registries, see below for a further discussion about model registries. To work around this issue you can use any of the following built-in model classes:

- `Reynard::Naming::DigestModelNaming` produces a unique digest based on the schema, for example: `86f7e437faa5a7fce15d1ddcb9eaeaea377667b8`.
- `Reynard::Naming::NodeModelNaming` uses the node in the specification as its name, for example: `['/item/{id}', 'get', 'responses', '200', 'content', 'application/json', 'schema']`.

Note that models may be cached in a global registry so changing model naming late may lead to unexpected results.

A custom model naming object should respond to a `call` method that takes any of three keyword arguments;

- `specification:` – an instance of `Reynard::Specification`.
- `node:` – path to the response schema, used as `specification.dig(*node, 'title')`
- `namespace:` – current namespace when part of another object (eg. `['Library', 'Book']`), but usually `nil`

This allows you to do something like this:

```ruby
class TitleModelNaming
  def call(specification:, node:, namespace:)
    [
     *namespace,
     specification.dig(*node, 'title')
    ].join('::')
  end
end

reynard.model_naming(TitleModelNaming.new)
```

Or the same thing as a Proc:

```ruby
reynard.model_naming(->(specification:, node:, namespace:) {
  [
   *namespace,
   specification.dig(*node, 'title')
  ].join('::')
})
```

#### Model registry

A model registry exists for two reasons:

1. It reduces the time spent building model classes
2. Allows you to take control of a model definition and extend it somehow

Default model registry in Reynard gets and sets constants on `Reynard::Models` based on the result of the model naming class. For example, when model naming produces the name `LibraryBook` it will define a constant named `Reynard::Models::LibraryBook`.

You can open up this class and extend it, for example:

```ruby
class Reynard
  module Models
    class LibraryBook
      include MyModelHelpers

      def blank?
        empty?
      end
    end
  end
end
```

As explained before this might cause issues with duplicate names because a response may return an object created with the wrong class constant. To work around this issue you can use any of the following built-in model registries:

- `Reynard::Naming::KeyedModelRegistry` which uses key / value pairs to store the model classes, meaning you can't defined constants as explained above.

You can still get and set the model from `KeyedModelRegistry` by their model name so you an still take control.

```ruby
model = Class.new(Reynard::Model)
model.include(MyModelHelpers)
registry = Reynard::Naming::KeyedModelRegistry.new
registry.set(model_name: 'Reynard::Models::LibraryBook', model:)
client = reynard.model_registry(registry)
```

A custom model naming object should respond to `get(model_name:)` and `set(model_name:, model:)` methods, for example:

```ruby
class HashModelRegistry
  def initialize
    @models = {}
  end

  def set(model_name:, model:)
    if model
      @models[model_name] = model
    else
      @models.delete(model_name)
    end
  end

  def get(model_name:)
    @models[model_name]
  end
end

reynard.model_registry(HashModelRegistry.new)
```

Note that this basically introduces a global state for Reynard for the process. If this leads to further problems you can also turn off the model registry entirely by setting it to `nil`:

```ruby
reynard.model_registry(nil)
```

#### Taking control of a model

As explained earlier you can take control of a model definition. The easiest way to find a model name is to actually perform the operation and look at the response. Let's look at an example where Reynard creates a `Library` model:

```ruby
response.object.model_name #=> Reynard::Models::Library
response.parsed_body #=> {"name" => "Alexandria"}
```

Let's assume you want to implement a method to see if the response payload is usable in your application.

```ruby
class Reynard
  module Models
    class Library < Reynard::Model
      def usable?
        (%w[name] - @attributes.keys).empty?
      end
    end
  end
end
```

Next time you perform a request you can use your version of `Library`:

```ruby
if response.object.valid?
  puts "The library is valid!"
else
  puts "The library is not valid :-( #{response.parsed_object.inspect}"
end
```

See the implementation of `Reynard::Model` for more details.

## Logging and debugging

When you want to know what the Reynard client is doing you can enable logging.

```ruby
logger = Logger.new($stdout)
logger.level = Logger::INFO
reynard.logger(logger).execute
```

The logging should be compatible with the Ruby on Rails logger.

```ruby
reynard.logger(Rails.logger).execute
```

You can turn on debug logging in `Net::HTTP` and other internals by setting the `DEBUG` environment variable at the start of the process. After setting this, all HTTP interaction and object building details will be written to STDERR.

```sh
env DEBUG=true ruby script.rb
```

Internally this will set `http.debug_output = $stderr` on the HTTP object in the client.

## Mocking

You can mock Reynard requests by changing the HTTP implementation. The class **must** implement a single `request` method that accepts a URI and net/http request object. It **must** return a net/http response object or an object with the exact same interface.

```ruby
Reynard.http = MyMock.new

class MyMock
  def request(uri, net_http_request)
    Net::HTTPResponse::CODE_TO_OBJ['404'].new('HTTP/1.1', '200', 'OK')
  end
end
```

## Contributing

See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md).

## Copyright and other legal

See [LICENCE](LICENCE).
