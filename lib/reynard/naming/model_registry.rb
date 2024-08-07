# frozen_string_literal: true

class Reynard
  module Naming
    # Keeps track of previously built models to reduce response processing time and to allow
    # users to take control over model definitions.
    class ModelRegistry
      def set(model_name:, model:, namespace: nil)
        self.class.mutex.synchronize do
          namespace = [nil, 'Reynard', 'Models', *namespace.to_s.split('::')].compact.join('::')
          array_set(
            namespace: Kernel.const_get(namespace),
            model_name: model_name.split('::'),
            model: model
          )
        end
      end

      def get(model_name:, namespace: nil)
        self.class.mutex.synchronize do
          namespace = [nil, 'Reynard', 'Models', *namespace.to_s.split('::')].compact.join('::')
          array_get(
            namespace: Kernel.const_get(namespace),
            model_name: model_name.split('::')
          )
        end
      rescue NameError
        nil
      end

      def self.mutex
        @mutex ||= Mutex.new
      end

      private

      def array_set(namespace:, model_name:, model:)
        case model_name.length
        when 1
          const_set(namespace: namespace, name: model_name[0], model: model)
        else
          model_module = ensure_namespace(namespace: namespace, name: model_name[0])
          array_set(namespace: model_module, model_name: model_name[1..], model: model)
        end
      end

      def const_set(namespace:, name:, model:)
        # Because we're rummaging around in our "own" namespace it should be safe to move around
        # class definitions.
        if namespace.const_defined?(name)
          const_copy(from: namespace.const_get(name), to: model)
          begin
            namespace.send(:remove_const, name)
          rescue StandardError
            NameError
          end
        end
        namespace.const_set(name, model)
      end

      def const_copy(from:, to:)
        from.constants.each do |const|
          to.const_set(const, from.const_get(const))
        end
      end

      def ensure_namespace(namespace:, name:)
        namespace.const_get(name)
      rescue NameError
        namespace.const_set(name, Class.new)
      end

      def array_get(namespace:, model_name:)
        case model_name.length
        when 1
          namespace.const_get(model_name[0], false)
        else
          model_module = namespace.const_get(model_name[0], false)
          array_get(namespace: model_module, model_name: model_name[1..])
        end
      end
    end
  end
end
