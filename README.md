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
base_url = reynard.servers.map(&:url).find do |url|
  /staging/.match(url)
end
reynard.base_url(base_url)
```

## Calling endpoints

Assuming there is an operation called `employeeByUuid` you can it as shown below.

```ruby
response = reynard.
  operation('employeeByUuid').
  params(uuid: uuid).
  execute
```

When an operation requires a body, you can add it as structured data.

```ruby
response = reynard.
  operation('createEmployee').
  body(name: 'Sam Seven').
  execute
```

In case the response matches a response in the specification it will attempt to build an object using the specified schema.

```ruby
response.object.name #=> 'Sam Seven'
```

The response object shared much of its interface with `Net::HTTP::Response`.

```ruby
response.code #=> '200'
response.content_type #=> 'application/json'
response['Content-Type'] #=> 'application/json'
response.body #=> '{"name":"Sam Seven"}'
response.parsed_body #=> { "name" => "Sam Seven" }
```

## Schema and models

Reynard has an object builder that allows you to get a value object backed by model classes based on the resource schema.

For example, when the schema for a response is something like this:

```yaml
book:
  type: object
  properties:
    name:
      type: string
    author:
      type: object
      properties:
        name:
          type: string
```

And the parsed body from the response is:

```json
{
  "name": "Erebus",
  "author": { "name": "Palin" }
}
```

You should be able to access it using:

```ruby
response.object.class #=> Reynard::Models::Book
response.object.author.class #=> Reynard::Models::Author
response.object.author.name #=> 'Palin'
```

### Model name

Model names are determined in order:

1. From the `title` attribute of a schema
2. From the `$ref` pointing to the schema
3. From the path to the definition of the schema

```yaml
application/json:
  schema:
    $ref: "#/components/schemas/Book"
components:
  schemas:
    Book:
      type: object
      title: LibraryBook
```

In this example it would use the `title` and the model name would be `LibraryBook`. Otherwise it would use `Book` from the end of the `$ref`.

If neither of those are available it would look at the full expanded path. 

```
books:
  type: array
  items:
    type: object
```  

For example, in case of an array item it would look at `books` and singularize it to `Book`.

If you run into issues where Reynard doesn't properly build an object for a nested resource, it's probably because of a naming issue. It's advised to add a `title` property to the schema definition with a unique name in that case.

### Properties and model attributes

Reynard provides access to JSON properties on the model in a number of ways. There are some restrictions because of Ruby, so it's good to understand them.

Let's assume there is a payload for an `Author` model that looks like this:

```json
{"first_name":"Marcél","lastName":"Marcellus","1st-class":false}
```

Reynard attemps to give access to these properties as much as possible by sanitizing and normalizing them, so you can do the following:

```ruby
response.object.first_name #=> "Marcél"
response.object.last_name #=> "Marcellus"
```

But it's also possible to use the original casing for `lastName`.

```ruby
response.object.lastName #=> "Marcellus"
```

However, a method can't start with a number and can't contain dashes in Ruby so the following is not possible:

```
# Not valid Ruby syntax:
response.object.1st-class
```

There are two alternatives for accessing this property:

```ruby
# The preferred solution for accessing raw property values is through the
# parsed JSON on the response object.
response.parsed_body["1st-class"]
# When you are processing nested models and you don't have access to the
# response object, you can chose to use the `[]` method.
response.object["1st-class"]
# Don't use `send` to access the property, this may not work in future
# versions.
response.object.send("1st-class")
```

#### Mapping properties

In case you are forced to access a property through a method, you could chose to map irregular property names to method names globally for all models:

```ruby
reynard.snake_cases({ "1st-class" => "first_class" })
```

This will allow you to access the property through the `first_class` method without changing the behavior of the rest of the object.

```ruby
response.object.first_class #=> false
response.object["1st-class"] #=> false
```

Don't use this to map common property names that would work fine otherwise, because you could make things really confusing.

```ruby
# Don't do this.
reynard.snake_cases({ "name" => "naem" })
```

## Logging

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

## Debugging

You can turn on debug logging in `Net::HTTP` by setting the `DEBUG` environment variable. After setting this, all HTTP interaction will be written to STDERR.

```sh
env DEBUG=true ruby script.rb
```

Internally this will set `http.debug_output = $stderr` on the HTTP object in the client.

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
