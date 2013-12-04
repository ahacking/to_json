#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'benchmark'
require 'oj'
require 'to_json'
require 'jbuilder'
require 'json_builder'
require 'jsonify'

enough = 500_000
puts "JSONBuilder original benchmark (#{enough} complex objects):"

Benchmark.bm(15) do |b|
  b.report('ToJson (class)') do
    class BenchmarkSerializer < ToJson::Serializer
      def serialize
        put :name, "Garrett Bjerkhoel"
        put :birthday, Time.local(1991, 9, 14)
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
    enough.times {
      BenchmarkSerializer.json!
    }
  end
  b.report('ToJson (block)') do
    enough.times {
      ToJson::Serializer.json! {
        put :name, "Garrett Bjerkhoel"
        put :birthday, Time.local(1991, 9, 14)
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
  b.report('Jbuilder') do
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
  b.report('JSONBuilder') do
    enough.times {
      JSONBuilder::Compiler.generate {
        name "Garrett Bjerkhoel"
        birthday Time.local(1991, 9, 14)
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
  b.report('jsonify') do
    enough.times {
      json = Jsonify::Builder.new
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
      json.compile!
    }
  end
end
