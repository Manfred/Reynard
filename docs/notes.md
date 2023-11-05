# Performance

## One big specification

The guiding performance principle behind Reynard is that Ruby generally performs best when you keep the number of object allocations as low as possible.

Based on this principle Reynard keeps the parsed JSON structure in memory as one big specification and used an interface that resembles `Hash#dig` to get to objects within the structure.

Results from interacting with the specification generally contain a path like `['authors', 0, 'name']` to the result instead of duplicating the value of the result.

The assumption is that Ruby types are optimized for performing these kinds of operations.

## Net::HTTP is fast and TLS connections are slow

When you look up benchmarks littered across the internet you will find that Ruby's Net::HTTP will perform the same or better than using bindings to popular HTTP libraries like curl.

One of the reasons is likely that the network operations are the slow part of any HTTP request and not building the request object or parsing the response.

Establishing secure connections to a server can be slow so Reynard relies on `net-http-persistent` to keep the connection around.

## Parsing and generating JSON

Parsing and generating large amounts of JSON will be slower when you use Ruby's built-in JSON implementation. Reynard uses `multi-json` to allow applications to optionally install a faster JSON implementation.
