# frozen_string_literal: true

# Example of an application controller where the Reynard instance relies on an initialized Ruby on
# Rails application.
class ApplicationController < ActionController::Base
  protected

  include Client

  def client_with_store
    # See libraries_controller.rb file for an example that enables a feature that requires a store.
    client.
      # Use Rails.cache to keep small values in between requests.
      metadata_store(Rails.cache).
      # Use disk store for response bodies and larger values.
      data_store(client_data_store)
  end

  private

  def client_data_store
    Reynard::Store::Disk.new(path: Rails.application.config.data_store_path)
  end
end
