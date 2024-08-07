# frozen_string_literal: true

class Reynard
  # Wraps the content part of a request body and helps with determining the most suitable request
  # body content-type.
  class Content
    extend Forwardable
    def_delegators :@keys, :empty?

    attr_reader :keys

    def initialize(keys:)
      @keys = keys
    end

    def pick_serializer(serializers)
      return unless serializers

      @keys.each do |key|
        next unless serializers.key?(key)

        return SerializerSelection.new(
          content_type: key,
          serializer_class: serializers[key]
        )
      end

      nil
    end
  end
end
