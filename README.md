# ToJson

A performant Ruby JSON Serializer DSL for Oj.

Why? Because current Ruby JSON serialisers take too long and use too
much memory or can't express **all** valid JSON structures.

ToJSON is ORM and ruby web framework agnostic and designed for serving fast and flexible JSON APIs.

## Installation

Add this line to your application's Gemfile:

    gem 'to_json'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install to_json

## Design

Pragmatism and performance is a big driver as existing solutions spend far too much time generating JSON or limit the JSON
structure you can express.  ToJson does NOT use a Rails ActionView template approach, instead the DSL is intended to be used
directly or within serializer classes. This means ToJson supports all of the expressive power of real Ruby classes including
inheritence, mixins, delegates etc and doesnt need to implement quasi equivalents in a templating language.

What does this mean? It means you can easily DRY up your JSON API's, easily version your API's, keep your model helpers and
formatters scoped and not have the performance and expressive limitations of existing template approaches.

Additionally ToJson is designed to not require Ruby language features like method_missing because its about 7 times slower
than a regular method call for very minor syntactical advantage.

ToJson leverages the awesome Oj gem for the fastest available JSON serialization in Ruby.

## ToJson Alternatives

Some alternatives to ToJson and primary diferences.

### ToJson vs JBuilder
 + ToJson does not rely on method_missing
 + ToJson does not use templating and is both faster and more powerful because of it
 + Value conversion defers to Oj for speed
 + ToJson is ruby web framework agnostic

### ToJson vs ActiveModel::Serializers
 + ToJson is ORM agnostic
 + ToJson does not try to lookup serializers based on the model class.  If you care about API versioning you will realize that the
   controller MUST decide this.
 + ToJson deferes value conversion to Oj for speed
 + ToJson does not have a DSL syntax that gets in the way of expressing any JSON structure you like.

### ToJson vs RABL
 + ToJson does not have a complex (insane) syntax that prevents you expressing any JSON structure you like.
 + ToJson does not mess with the ordering serialized items.
 + ToJson DSL is simpler and far more expressive and no nasty surprises.
 + ToJson uses real Ruby classes for inheritence, mixins and composition.
 + ToJson supports helpers and presenter methods in the serializer class or via mixins.
 + ToJson deferes value conversion to Oj for speed

### ToJson vs ROAR
 + ToJson doesnt try to `extend` your model instances and invalidate the Ruby method cache (big perfomance killer).
 + ToJson supports helpers and presenter methods in the serializer
class, and doesnt require lambas (required if using ROAR's decorator approach to get around the extend problem.)
 + ToJson uses real Ruby classes for inheritence, mixins and composition.
 + ToJson allows you to express any JSON structure you like.
 + ToJson deferes value conversion to Oj for speed
 + ToJson is currently one-way serialization (ROAR is bi-directional)
 + Roar has explicit suppor for JSON+HAL, but you can easily express JSON+HAL in ToJson (example below).

## Benchmarks

```
$ test/benchmark
$ bundle install
$ ./benchmark.rb

                    user     system      total        real
ToJson (class)  2.010000   0.020000   2.030000 (  2.032673)
ToJson (block)  3.400000   0.030000   3.430000 (  3.459350)
Jbuilder        6.980000   0.030000   7.010000 (  7.116469)
JSONBuilder    13.250000   0.070000  13.320000 ( 13.418005)
```

Simulate encoding 10,000 objects with 20 attributes each, approx 800 bytes per item (7.6Mb total):

```ruby
require 'benchmark'
require 'to_json'
require 'jbuilder'

enough = 10000
Benchmark.bm do |x|
  x.report("Raw string interpolation") { enough.times {
    20.times { |n| "foo-#{n}: #{'bar' * n }" } } }
  x.report("ToJson (class)") { enough.times {
    ToJson::Serializer.new { 20.times { |n| put "foo-#{n}", ('bar' * n) } } } }
  x.report("ToJson (block)") { enough.times {
    ToJson::Serializer.new { 20.times { |n| put "foo-#{n}", ('bar' * n) } } } }
  x.report("Jbuilder") { enough.times {
    Jbuilder.encode { |json| 20.times { |n| json.set! "foo-#{n}", ('bar' * n) } } } }
end
```

TODO. Add ROAR and RABL to benchmark.

## Usage

## General Invocation with block

```ruby
  # args are optional
  ToJson::Serializer.new(args...) do |args...|
    # DSL goes here, callers methods, helpers, instance variables and constants are all in scope
  end
end
```

### Invocation from Rails controller with block

```ruby
def index
  @post = Post.first
  # the rails responder will call to_json on the ToJson object
  respond_with ToJson::Serializer.new do
    # DSL goes here, contoller methods, helpers, instance variables and constants are all in scope
  end
end
```

### Invocation from Rails controller with custom serializer class (recommended)

```ruby
def index
  # we just pass the collection instead of the controller to allow for composition of JSON serializers
  respond_with PostsSerializer.new(Post.all)
end
```

### JSON Objects

The `put` method is used to serialize named object values and
create arbitarily nested objects.

All values will be serialized according to Oj processing rules.

#### Example creating an object with named values:

```ruby
put :title, @post.title
put :body, @post.body
```

#### Example creating a nested object

```ruby
put :post do
  put :title, @post.title
  put :body, @post.body
end
```

### Example of a named object literal

The hash value under 'author' will be serialized by Oj.

```ruby
put :author, {name: 'Fred', email: 'fred@example.com', age: 27}
```

### Example of an object literal

The hash value will be serialized by Oj.

```ruby
value {name: 'Fred', email: 'fred@example.com', age: 27}
```

#### Example creating a nested object with argument passed to block

```ruby
put :latest_post, current_user.posts.order(:created_at: :desc).first do |post|
  put :title, post.title
  put :body, post.body
end
```

### JSON Arrays

Arrays provide aggregation in JSON and are created with the `array` method.  Array
elements can be created through:
+ a literal value passed to `array` without a block
+ evaluating blocks over the argument passed to array (similar to `each`)
+ evaluating a block with no argument

Within the array block, array elements can be created using `value`, however this is
called implicitly for you when using `put` or `array` inside the array block.

### Example of an array literal

The literal array value will be passed to Oj for serialization.

```ruby
array ['Fred', 'fred@example.com', 27]
```

### Example of an array collection

The @posts collection will be passed to Oj for serialization.

```ruby
array @posts
```

### Example of array with block for custom object serialization

```ruby
array @posts do |post|
  # calling put inside an array does an implicit 'value' call
  # placing all named values into a single object
  put :title, post.title
  put :body, post.body
end
```

### Example collecting post author emails into a single array.

Each post item will be processed and the email addresses of the author
serialized.

```ruby
array @posts do |post|
  @post.author.emails do |email|
    value email.address
  end
end
```

### Example creating array element values explicitly

The following example will an array containing 3 elements.

```ruby
array do
  value 'one'
  value 2
  value do
    put label: 'three'
  end
end
```

### Example creating array with a nested object and nested collection

```ruby
array do
  value do
    put :total_entries, @posts.total_entries
    put :total_pages, @posts.total_pages
  end
  array @posts do
    put :title, post.title
    put :body, post.body
  end
end
```

### Example creating a paged collection as per the HAL specification:

```ruby
put :meta do
  put :total_entries, @posts.total_entries
  put :total_pages, @posts.total_pages
end
put :collection, @posts do |post|
  put :title, post.title
  put :body, post.body
end
put :_links do
  put :self { put :href, url_for(page: @posts.current_page) }
  put :first { put :href, url_for(page: 1) }
  put :previous { @posts.current_page <= 1 ? nil : put :href, url_for(page: @posts.current_page-1) }
  put :next { current_page_num >= @posts.total_pages ? nil : put :href, url_for(page: @posts.current_page+1) }
  put :last { put :href, url_for(page: @posts.total_pages) }
end
```

### Example of nested arrays, and dynamic array value generation:

```ruby
array do
  # this nested array is a single value in the outer array
  array do
    value 'a'
    value 'b'
    value 'b'
  end
  # this nested array is a single value in the outer array
  array (1..3)
    (1..4).each do |count|
      # generate 'count' values in the nested array
      count.times { value "item #{count}" }
    end
  end
end
```

### Example of implicit array creation

```ruby
# calling value here simply creates an object
value 
  put total_entries: 123
end
# calling 'value' a second time implicitly creates an outer  array
value 'some string'
# this will also be nested inside the implicit outer array
array @posts do
  put :title, post.title
  put :body, post.body
end
```

### Example of implicit array creation

```ruby
# serialize an object
put total_entries: 123
# calling 'value' here implicitly creates an outer array
value 'some string'
# this will also be nested inside the outer array too
array @posts do
  put :title, post.title
  put :body, post.body
end
```

### Example of defining and using a helper

def fullname(*names)
  names.join(' ')
end

put :author, fullname(@post.author.first_name, @post.author.last_name)
```

### Example of class based serialization and composition:

```ruby

# A Post model serializer
class PostSerializer < ToJson::Serializer
  include PostSerialization

  # override the build method and use the ToJson DSL
  def serialize
    build_post_with_root scope
  end
end

# A Post collection serializer
class PostsSerializer < ToJson::Serializer
  include PostSerialization

  def serialize
    build_posts scope
  end
end

# define a module so we can mixin Post model serialization code and avoid
# temporary builder objects for collection items
module PostSerialization
  # formatting helper
  def fullname(*names)
    names.join(' ')
  end

  def serialize_post(post)
    put :title, post.title
    put :body, post.body
    put :author, fullname(post.author.first_name, post.author.last_name)
    put :comments, CommentsSerializer.new(post.comments)
  end

  def serialize_post_with_root(post)
    put :post do
      serialize_post post
    end
  end

  def serialize_posts(posts)
    put :meta do
      put :total_entries, posts.total_entries
      put :total_pages, posts.total_pages
    end
    put :collection, posts.each(&:serialize_post)
  end
end
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
