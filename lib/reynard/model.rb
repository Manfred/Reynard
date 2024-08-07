# frozen_string_literal: true

class Reynard
  # Class or superclass for all models generated by Reynard.
  class Model < BasicObject
    include ::PP::ObjectMixin
    extend ::Forwardable
    def_delegators :@attributes, :[], :empty?

    class << self
      # Allows Reynard to name a model when it's not defined as a constant.
      attr_accessor :name

      # When Reynard found a schema in the specification for the response this will contain a
      # Hash keyed on the property name with details about the property.
      attr_accessor :properties

      # Contains the module or class namespace when built in relation to another model. For
      # example: "Library::Author".
      attr_accessor :namespace
    end

    def initialize(attributes, response_context = nil)
      @response_context = response_context
      if attributes.respond_to?(:each) && attributes.respond_to?(:keys)
        @attributes = {}
        self.attributes = attributes
      else
        ::Kernel.raise(
          ::ArgumentError,
          self.class.attributes_error_message(attributes)
        )
      end
    end

    # We rely on these methods for various reasons so we re-introduce them at the expense of
    # allowing them to be used as attribute name for the model.
    %i[class is_a? nil? object_id kind_of? respond_to? send].each do |method|
      define_method(method, ::Kernel.method(method))
    end

    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} #{@attributes.inspect}>"
    end

    def attributes=(attributes)
      attributes.each do |name, value|
        @attributes[name.to_s] = value
      end
    end

    def method_missing(attribute_name, *)
      return false unless @attributes

      attribute_name = attribute_name.to_s
      unless @attributes.key?(attribute_name)
        ::Kernel.raise(
          ::NoMethodError,
          "undefined method `#{attribute_name}' for #{inspect}"
        )
      end

      @attributes[attribute_name]
    end

    def respond_to_missing?(attribute_name, *)
      @attributes.key?(attribute_name.to_s)
    end

    def try(attribute_name)
      respond_to?(attribute_name) ? send(attribute_name) : nil
    end

    def self.attributes_error_message(attributes)
      'Models must be intialized with an enumerable object that behaves like a Hash, got: ' \
        "`#{attributes.inspect}'. Usually this means the schema defined in the OpenAPI " \
        "specification doesn't fit the payload in the HTTP response."
    end
  end
end
