# frozen_string_literal: true

# In general, the only cost to creating a Reynard context is instantiating a new class. There are
# moments when Reynard reads a specification from disk, so there are key moments when memoization
# makes sense, but you probably shouldn't overdo it. The actual HTTP client used by Reynard is
# usually a global so it can deal with persistent connections (see: Reynard.http).
#
# Sorry if the example is overly specific to Ruby on Rails, thems the breaks.
#
# Some considerations
#
# * Having a global for a client instance is necessary for performance, but it's also not great to
# litter it across the application if you ever need to controller or command class specific tweaks
# to the client.

# Configures a Reynard client for use in various parts of the application.
module Client
  # Returns a Reynard::Context instance, which can be used to perform OpenAPI operations.
  def client
    Client.client
  end

  class << self
    def specification_filename
      # NOTE: If you're not using Rails, you can replace this with anything that makes sense for
      # your setup.
      Rails.root.join('openapi/consuming.yml').to_s
    end

    def logger
      # If you're not using Rails, you can replace this with any logger that shares an interface
      # with the default Ruby Logger class.
      Rails.logger
    end

    def user_agent
      # We include both versions in the user agent string to help with monitoring. Anyone
      # responsible for operations will love you for doing this.
      "MyApplication/#{short_release_version} Reynard/#{Reynard::VERSION}"
    end

    private

    def client
      @client ||= reynard_context
    end

    def reynard_context
      # Allows us to query servers from the specification. If you always use the first server
      # definition you can immediately chain the rest of the calls.
      reynard = Reynard.new(filename: specification_filename)
      reynard
        .logger(logger)
        .base_url(choose_server(reynard.servers))
        .headers({ 'User-Agent' => user_agent, 'Accept' => 'application/json' })
    end

    def choose_server
      # OpenAPI doesn't have properties to specify server intent, but sometimes the list of servers
      # is misused to specify different environments or deployments. In this example the author of
      # the specification decided to misuse the description to specify the environment. For example:
      #
      #   servers:
      #     - description: production
      #       url: https://production.example.com/v0
      #     - description: staging
      #       url: https://staging.example.com/v1
      servers.find do |server|
        server.description.include?(Rais.env)
      end.url
    end

    def short_release_version
      # This may not be ideal, unsafe, or not performant. You probably have a sensible way of
      # retrieving the application version already.
      `git rev-parse --short HEAD`
    end
  end
end
