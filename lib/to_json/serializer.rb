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

    # Put an array
    def array(*args, &block)
      if block
        @_oj.push_array @_key                               # open the array (with or without key as required)
        @_key = nil                                         # clear key
        obj_depth = @_obj_depth                             # save object depth
        if args.count == 0                                  # if no collection just invoke block
          @_obj_depth = 0                                   # clear object serialization state
          block.call                                        # yield to the block
          @_oj.pop if @_obj_depth > obj_depth               # automatically close nested objects
        else
          args = args[0] if args.count == 1                 # get array arg otherwise treat as implicit array
          args && args.each do |item|                       # serialize each item using the block
            @_obj_depth = 0                                 # reset object depth to zero for array elements
            block.call item                                 # yield item to the block
            @_oj.pop if @_obj_depth > 0                     # automatically close nested objects
          end
        end
        @_oj.pop                                            # close the array
        @_obj_depth = obj_depth                             # restore object depth
      else
        args = args[0] || [] if args.count == 1             # collection argument, treat nil as empty
                                                            # all other cases args is implicit array
        @_oj.push_value args, @_key                         # serialize collection using Oj with or without key
      end
    end

    # Put a value
    def value(value=nil, &block)
      put! nil, value, &block                               # serialize the value
    end

    # Put a named value
    def put(key, value=nil, &block)
      put! key.to_s, value, &block                          # serialize the key and value
    end

    #
    # field helpers
    #

    # Put an object field unless the value is nil
    def put_field_unless_nil(obj, field, as=nil, &block)
      put_field_unless :nil?, obj, field, as, &block
    end

    # Put an object field unless the value is blank
    def put_field_unless_blank(obj, field, as=nil, &block)
      put_field_unless :blank?, obj, field, as, &block
    end

    # Put an object field unless value condtion is true
    def put_field_if(condition, obj, field, as=nil, &block)
      value = obj.send(field)
      put! (as || field).to_s, value, &block if value.send(condition)
    end

    # Put an object field if value condition is true
    def put_field_unless(condition, obj, field, as=nil, &block)
      value = obj.send(field)
      put! (as || field).to_s, value, &block unless value.send(condition)
    end

    # Put an object field
    def put_field(obj, field, as, &block)
      put! (as || field).to_s, obj.send(field), &block
    end

    # Put specified object fields with optional mapping.
    #
    # The DSL accepts array pairs, hashes, arrays containing any
    # mix of array or hash pairs.
    #
    # The following examples are all equivalent and map 'title' to 'the_tile'
    # and 'created_at' to 'post_date' and leave 'body' as is.
    #
    # put_fields @post, [:title, :the_title], :body, [:created_at, :post_date]
    # put_fields @post, [[:title, :the_title], :body, [:created_at, :post_date]]
    # put_fields @post, {title: :the_title, body: nil, created_at: :post_date}
    # put_fields @post, [:title, :the_title], :body, {:created_at => :post_date}
    # put_fields @post, {title: :the_title}, :body, {created_at: :post_date}
    def put_fields(obj, *keys)
      keys.each do |key, as|                                # could be any enumerable, type may be nil
        if key.is_a? Hash
          put_fields obj, key                               # recurse to expand hash
        else
          put! (as || key).to_s, obj.send(key)
        end
      end
    end

    # Put specified object fields unless blank.
    #
    # The field keys can be mapped as per put_fields
    def put_fields_unless_blank(obj, *keys)
      put_fields_unless :blank?, obj, *keys
    end

    # Put specified object fields unless nil.
    #
    # The field keys can be mapped as per put_fields
    def put_fields_unless_nil(obj, *keys)
      put_fields_unless :nil?, *obj, keys
    end

    # Put specified object unless the field value condition is true.
    #
    # The field keys can be mapped as per put_fields
    def put_fields_unless(condition, obj, *keys)
      keys.each do |key, as|                                # could be any enumerable, type may be nil
        if key.is_a? Hash
          put_fields_unless condition, obj, key             # recurse to expand hash
        else
          put_field_unless condition, obj, key, as
        end
      end
    end

    # Put specified object if field value condition is true.
    #
    # The field keys can be mapped as per put_fields.
    def put_fields_if(condition, obj, *keys)
      keys.each do |key, as|                                # could be any enumerable, type may be nil
        if key.is_a? Hash
          put_fields_if condition, obj, key                 # recurse to expand hash
        else
          put_field_if condition, obj, key, as
        end
      end
    end

    #
    # put object primitive
    #

    def put!(key=nil, value=nil, &block)
      if @_key                                              # existing saved key?
        if key                                              # nesting a key under a key forces object creation!
          @_obj_depth += 1                                  # increase object depth
          @_oj.push_object @_key                            # push start of named object
        else
          key = @_key                                       # unstash saved key
        end
      end

      if block
        @_key = key                                         # stash current key for block call
        obj_depth = @_obj_depth                             # save current object depth to detect object creation
        block.call(value)                                   # yield value to the block
        @_oj.pop if @_obj_depth > obj_depth                 # automatically close any nested object created by block
        @_obj_depth = obj_depth                             # restore object depth
      else
        if key && @_obj_depth == 0                          # key present and no outer object?
          @_obj_depth += 1                                  # increase object depth
          @_oj.push_object                                  # push anonymous object
        end
        @_oj.push_value value, key                          # serialize value using Oj with or without key
      end
      @_key = nil                                           # ensure key is cleared
    end

    def method_missing(method, *args, &block)
      # delegate to the scope
      @_scope.send method, *args, &block
    end

    def const_missing(name)
      # delegate to the scope
      @_scope.class.const_get name
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
