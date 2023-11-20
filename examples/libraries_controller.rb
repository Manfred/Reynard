# frozen_string_literal: true

# Controller that fetches a collection that hardly ever changes and supports conditional requests.
class AuthorsController < ApplicationController
  include Client

  def show
    response = client_with_conditional_requests.operation('getLibraries').execute
    if response.ok?
      render :show, locals: { author: response.object }
    elsif response.client_error?
      head :not_found
    else
      head :internal_server_error
    end
  end

  private

  def client_with_conditional_requests
    # Conditional requests may store resources, so we only want to enable it for specific cases
    # where we know it makes sense.
    client_with_store.enable(:conditional_requests)
  end
end
