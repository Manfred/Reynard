# frozen_string_literal: true

# Example of a simple controller that performs a request to another service and then renders the
# dynamic model in a template.
class AuthorsController < ApplicationController
  include Client

  def show
    response = client.operation('getAuthor').params(id: params[:id]).execute
    if response.ok?
      render :show, locals: { author: response.object }
    elsif response.client_error?
      head :not_found
    else
      head :internal_server_error
    end
  end
end
