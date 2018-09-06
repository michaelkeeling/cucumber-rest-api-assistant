require 'json'

module CucumberApiAssistant
  module Helpers

    
    def self.get_env(key)
      #Automatically try to be case insensitive
      value = ENV[key] || ENV[key.downcase] || ENV[key.upcase]
      CucumberApiAssistant::TestLogger.debug "Read #{key} from the environment as '#{value}'"
      value
    end

    def self.compare_unordered_lists(a, b)
      if ( ((a - b) + (b - a)).empty? == false)
        return false
      end
      a_counts = self.inject_counts(a)
      b_counts = self.inject_counts(b)
      return a_counts == b_counts
    end

    def self.inject_counts(a)
      return a.inject(Hash.new(0)) {|h,i| h[i] += 1; h }
    end

    def self.fetch_from_JSON_with_shorthand(shorthand_key, json_object)
      keys = shorthand_key.split("/")
      value = JSON.parse(json_object)
      return traverse_json_object(keys, value)
    end

    def self.key_exists_in_JSON_with_shorthand(shorthand_key, json_object)
      keys = shorthand_key.split("/")
      last_key = keys.pop()
      value = JSON.parse(json_object)
      value = traverse_json_object(keys, value)
      return value.key?(last_key)
    end

    def self.traverse_json_object(keys, json_object)
      keys.each { |k|
        k = k.to_i if k.to_i.to_s == k
        json_object = json_object[k]
      }
      return json_object
    end

  end
end
