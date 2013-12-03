require 'active_support'
require 'oj'

class ToJson::Serializer
  def initialize(*args, &block)
    opts = args.extract_options!
    if ivars = opts[:ivars]
      ivars.each { |sym, value| instance_variable_set sym, value }
    end

    @_scope = args[0]
    @_node = nil
    @_object = nil
    serialize(*args, &block)
  end

  def self.serialize_each!(enumerable, &block)
    enumerable.map {|item| self.new(item, &block)}
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

  def to_a
    @_node.to_a
  end

  def to_h
    @_node if @_node.is_a? Hash
  end

  def as_json
    # when nested in another builder Oj will serialize _node for us
    @_node
  end

  def to_json
    # cache the json
    @_json ||= Oj.dump(@_node, {mode: :compat})
  end

  def to_s
    to_json
  end

  def node
    @_node
  end

  def scope
    @_scope
  end

  def inspect
    @_node.inspect
  end

  def array(collection = nil, &block)
    @_node ||= []

    if ! @_node.is_a? Array
      # call 'value' to implicitly create an outer array
      value(collection, &block)
    else
      if block
        if collection.nil?
          yield
        else
          for item in collection
            yield item
            # we support an implicit call to 'value' if the block calls 'put' to create named values
            # therefore we need to ensure we always clear out @_object
            @_object = null
          end
        end
      else
        @_node = collection || []
      end
    end

    # return the node so that if array is called inside a block we yield the array
    @_node
  end

  def value(value=nil, &block)
    # resolve the value
    value = _value(value, &block)

    if @_node.nil?
      # when node is undefined, calling 'value' just puts an object
      @_node = value
    else
      if ! @_node.is_a? Array
        # when node is not an array, implicitly create an array containing the current node and the new value
        @_node = [@_node, value]
      else
        # node is an array already, just add value to it
        @_node << value
      end
    end

    # return the node so that the last value in a block yields the array
    @_node
  end

  def put(key, value=nil, &block)
    # support an implicit call to 'value' when 'put' is used inside an array block
    if @_node.is_a? Array
      unless @_object
        @_object = ::ActiveSupport::OrderedHash.new
        @_node << @_object
      end
      hash = @_object
    else
      @_node ||= ::ActiveSupport::OrderedHash.new
      hash = @_node
    end

    # set the value and return the hash
    hash[key] = _value(value, &block)
    hash
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

  def _value(value, &block)
    if block
      begin
        parent = @_node
        parent_object = @_object
        @_node = nil
        @_object = nil
        value = value.respond_to?(:each) && ! value.is_a?(Hash) ? array(value, &block) : block.call(value)
      ensure
        @_node = parent
        @_object = parent_object
      end
    end

    value
  end
end
