require 'active_support'
require 'oj'

class ToJson::Serializer
  def initialize(*args, &block)
    opts = args.extract_options!
    if ivars = opts[:ivars]
      ivars.each { |sym, value| instance_variable_set sym, value }
    end

    @_scope = args[0]
    @_is_obj = nil
    @_oj = Oj::StringWriter.new({mode: :compat}.merge!(opts[:oj] || {}))
    serialize(*args, &block)
    @_oj.pop_all
  end

  def self.serialize_each!(enumerable, &block)
    enumerable.map { |item| self.new(item, &block) }
  end

  def self.json!(*args, &block)
    new(*args, &block).to_json
  end

  def serialize(*args, &block)
    # the following line gets the callers 'self' so we can copy instance vars and delegate to it
    @_scope = ::Kernel.eval 'self', block.binding
    _copy_ivars scope
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
      @_key ? @_oj.push_array(@_key) : @_oj.push_array    # open the array (with or without key as required)
      @_key = nil                                         # clear key
      save_is_obj = @_is_obj                              # save object serialization state
      if collection.nil?
        @_is_obj = nil                                    # clear object serialization state
        block.call                                        # yield to the block
        @_oj.pop if @_is_obj                              # automatically close nested objects
      else
        collection.each do |item|                         # serialize each item using the block
          @_is_obj = nil                                  # clear object state
          block.call(item)                                # yield item to the block
          @_oj.pop if @_is_obj                            # automatically close nested objects
        end
      end
      @_oj.pop                                            # close the array
      @_is_obj = save_is_obj                              # restore object serialization state
    else
      @_key ?
        @_oj.push_value(collection, @_key) :              # serialize key and entire collection using Oj
        @_oj.push_value(collection)                       # serialize entire collection using Oj
    end
  end

  def value(value=nil, &block)
    put!(nil, value, &block)                              # serialize the value
  end

  def put(key, value=nil, &block)
    put!(key.to_s, value, &block)                         # serialize the key and value
  end

  def put!(key=nil, value=nil, &block)
    if block
      @_key ||= key                                       # don't clobber key with nested calls to value()
      if value.respond_to?(:each) && ! value.is_a?(Hash)  # test for enumerability but don't enumerate hashes
        array(value, &block)                              # treat as a call to array()
      else
        save_is_obj = @_is_obj                            # save object serialization state
        $_is_obj = nil                                    # clear object serialization state
        block.call(value)                                 # yield value to the block
        @_oj.pop if @_is_obj                              # automatically close nested objects
        @_is_obj = save_is_obj                            # restore object serialization state
      end
      @_key = nil                                         # ensure key is cleared regardless of what the block does
    else
      if @_key                                            # outer object key present?
        @_is_obj = true                                   # set object serialization flag
        @_oj.push_object(@_key)                           # push an object
        @_key = nil                                       # clear key
      end
      key ?
        @_oj.push_value(value, key) :                     # serialize key and value using Oj
        @_oj.push_value(value)                            # serialize value using Oj
    end
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
