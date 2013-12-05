require 'oj'

module ToJson

  #
  # Serialize module for inclusion into classes
  #
  module Serialize

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def encode!(*args, &block)
        new.encode!(*args, &block)
      end

      def json!(*args, &block)
        new.json!(*args, &block)
      end
    end

    #
    # instance methods
    #

    def json!(*args, &block)
      encode!(*args, &block)
      @_oj.to_s
    end

    def encode!(*args, &block)
      @_scope = args[0]
      @_obj_depth = 0
      if @_oj
        @_oj.reset
      else
        @_oj = Oj::StringWriter.new({mode: :compat})
      end
      serialize(*args, &block)
      @_oj.pop_all
      self
    end

    def serialize(*args, &block)
      # the following line gets the callers 'self' so we can copy instance vars and delegate to it
      @_scope = ::Kernel.eval 'self', block.binding
      _copy_ivars @_scope
      instance_exec(*args, &block)
    end

    def to_json
      @_oj.to_s
    end

    def to_s
      to_json
    end

    def scope
      @_scope
    end

    def array(collection = nil, &block)
      if block
        @_oj.push_array(@_key)                              # open the array (with or without key as required)
        @_key = nil                                         # clear key
        obj_depth = @_obj_depth                             # save object depth
        if collection.nil?
          @_obj_depth = 0                                   # clear object serialization state
          block.call                                        # yield to the block
          @_oj.pop if @_obj_depth > obj_depth               # automatically close nested objects
        else
          collection.each do |item|                         # serialize each item using the block
            @_obj_depth = 0                                 # reset object depth to zero for array elements
            block.call(item)                                # yield item to the block
            @_oj.pop if @_obj_depth > 0                     # automatically close nested objects
          end
        end
        @_oj.pop                                            # close the array
        @_obj_depth = obj_depth                             # restore object depth
      else
        @_oj.push_value(collection, @_key)                  # serialize collection using Oj with or without key
      end
    end

    def value(value=nil, &block)
      put!(nil, value, &block)                              # serialize the value
    end

    def put(key, value=nil, &block)
      put!(key.to_s, value, &block)                         # serialize the key and value
    end

    def put!(key=nil, value=nil, &block)
      if @_key                                              # existingsaved key?
        if key                                              # nesting a key under a key forces object creation!
          @_obj_depth += 1                                  # increase object depth
          @_oj.push_object(@_key)                           # push start of named object
        else
          key = @_key                                       # unstash saved key
        end
      end

      if block
        @_key = key                                         # stash current key for block call
        if value.respond_to?(:each) && ! value.is_a?(Hash)  # test for enumerability but don't enumerate hashes
          array(value, &block)                              # treat as a call to array()
        else
          obj_depth = @_obj_depth                           # save current object depth to detect object creation
          block.call(value)                                 # yield value to the block
          @_oj.pop if @_obj_depth > obj_depth               # automatically close any nested object created by block
          @_obj_depth = obj_depth                           # restore object depth
        end
      else
        if key && @_obj_depth == 0                          # key present and no outer object?
          @_obj_depth += 1                                  # increase object depth
          @_oj.push_object                                  # push anonymous object
        end
        @_oj.push_value(value, key)                         # serialize value using Oj with or without key
      end
      @_key = nil                                           # ensure key is cleared
    end

    def method_missing(method, *args, &block)
      # delegate to the scope
      @_scope.send(method, *args, &block)
    end

    def const_missing(name)
      # delegate to the scope
      @_scope.class.const_get(name)
    end

  private

    def _copy_ivars(object)
      vars = object.instance_variables - self.instance_variables
      vars.each { |v| instance_variable_set v, object.instance_variable_get(v) }
    end
  end

  #
  # Serializer class for inheritance
  #
  class Serializer
    include Serialize
  end
end
