#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'

require 'benchmark'
require 'oj'
require 'oj_mimic_json'
require 'to_json'
require 'jbuilder'
require 'json_builder'
require 'jsonify'

enough = 500_000
parallel = 16
puts "Serialize 500,000 objects separately:"
birthday = Time.local(1991, 9, 14)

Benchmark.bm(15) do |b|

  class AddressSerializer < ToJson::Serializer
    def serialize
      put :address, "1143 1st Ave"
      put :address2, "Apt 200"
      put :city, "New York"
      put :state, "New York"
      put :zip, 10065
    end
  end

  b.report('ToJson (class) - simple') do
    s = AddressSerializer.new
    enough.times {
      s.json!
    }
  end
  
  b.report("ToJson (class) - parallel (#{parallel*enough} ops)") do
    s = AddressSerializer.new
    parallel.times do
      Process.fork do
        enough.times { s.json! }
      end
    end
    Process.waitall
  end

  b.report('ToJson (class) - complex') do
    class BenchmarkSerializer < ToJson::Serializer
      def serialize(birthday)
        put :name, "Garrett Bjerkhoel"
        put :birthday, birthday
        put :street do
          put :address, "1143 1st Ave"
          put :address2, "Apt 200"
          put :city, "New York"
          put :state, "New York"
          put :zip, 10065
        end
        put :skills do
          put :ruby, true
          put :asp, false
          put :php, true
          put :mysql, true
          put :mongodb, true
          put :haproxy, true
          put :marathon, false
        end
        put :single_skills, ['ruby', 'php', 'mysql', 'mongodb', 'haproxy']
        put :booleans, [true, true, false, nil]
      end
    end
    s = BenchmarkSerializer.new
    enough.times {
      s.json!(birthday)
    }
  end

  b.report('ToJson (block) - simple') do
    s = ToJson::Serializer.new
    enough.times {
      s.json! {
        put :address, "1143 1st Ave"
        put :address2, "Apt 200"
        put :city, "New York"
        put :state, "New York"
        put :zip, 10065
      }
    }
  end

  b.report('ToJson (block) - complex') do
    s = ToJson::Serializer.new
    enough.times {
      s.json! {
        put :name, "Garrett Bjerkhoel"
        put :birthday, birthday
        put :street do
          put :address, "1143 1st Ave"
          put :address2, "Apt 200"
          put :city, "New York"
          put :state, "New York"
          put :zip, 10065
        end
        put :skills do
          put :ruby, true
          put :asp, false
          put :php, true
          put :mysql, true
          put :mongodb, true
          put :haproxy, true
          put :marathon, false
        end
        put :single_skills, ['ruby', 'php', 'mysql', 'mongodb', 'haproxy']
        put :booleans, [true, true, false, nil]
      }
    }
  end

  b.report('Jbuilder - simple') do
    enough.times {
      Jbuilder.encode { |json|
        json.address "1143 1st Ave"
        json.address2 "Apt 200"
        json.city "New York"
        json.state "New York"
        json.zip 10065
      }
    }
  end
  b.report('Jbuilder - complex') do
    enough.times {
      Jbuilder.encode { |json|
        json.name "Garrett Bjerkhoel"
        json.birthday Time.local(1991, 9, 14)
        json.street do
          json.address "1143 1st Ave"
          json.address2 "Apt 200"
          json.city "New York"
          json.state "New York"
          json.zip 10065
        end
        json.skills do
          json.ruby true
          json.asp false
          json.php true
          json.mysql true
          json.mongodb true
          json.haproxy true
          json.marathon false
        end
        json.single_skills ['ruby', 'php', 'mysql', 'mongodb', 'haproxy']
        json.booleans [true, true, false, nil]
      }
    }
  end

  b.report('JSONBuilder - complex') do
    enough.times {
      JSONBuilder::Compiler.generate {
        name "Garrett Bjerkhoel"
        birthday birthday
        street do
          address "1143 1st Ave"
          address2 "Apt 200"
          city "New York"
          state "New York"
          zip 10065
        end
        skills do
          ruby true
          asp false
          php true
          mysql true
          mongodb true
          haproxy true
          marathon false
        end
        single_skills ['ruby', 'php', 'mysql', 'mongodb', 'haproxy']
        booleans [true, true, false, nil] 
      }
    }
  end

  b.report('jsonify - complex') do
    enough.times {
      json = Jsonify::Builder.new
      json.name "Garrett Bjerkhoel"
      json.birthday birthday
      json.street do
        json.address "1143 1st Ave"
        json.address2 "Apt 200"
        json.city "New York"
        json.state "New York"
        json.zip 10065
      end
      json.skills do
        json.ruby true
        json.asp false
        json.php true
        json.mysql true
        json.mongodb true
        json.haproxy true
        json.marathon false
      end
      json.single_skills ['ruby', 'php', 'mysql', 'mongodb', 'haproxy']
      json.booleans [true, true, false, nil] 
      json.compile!
    }
  end
end
