# Reynard

Reynard is an OpenAPI client for Ruby. It operates directly on the OpenAPI specification without the need to generate any source code.

```ruby
# A Client does not have a fixed state and creating a new
# client will never incur a cost over creating the object
# itself.
client = Reynard.new(filename: 'openapi.yml')
```

## Calling endpoints

Fetch an employee.

```ruby
employee = reynard.
  operation('employeeByUuid').
  params(uuid: uuid).
  execute
```
