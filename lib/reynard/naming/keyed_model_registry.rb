# frozen_string_literal: true

class Reynard
  module Naming
    # Keeps track of previously built models to reduce response processing time and to allow
    # users to take control over model definitions.
    class KeyedModelRegistry
      def initialize
        @classes = {}
      end

      def set(model_name:, model:, namespace: nil)
        key = namespace ? "#{namespace}::#{model_name}" : model_name
        self.class.mutex.synchronize do
          @classes[key] = model
        end
      end

      def get(model_name:, namespace: nil)
        key = namespace ? "#{namespace}::#{model_name}" : model_name
        self.class.mutex.synchronize do
          @classes[key]
        end
      end

      def self.mutex
        @mutex ||= Mutex.new
      end
    end
  end
end
