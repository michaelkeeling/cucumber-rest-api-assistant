module CucumberApiAssistant
  
  class StateInfo
    
    def initialize
      @request_body = nil
      @headers = Hash.new
      @query_params = Hash.new
      @request_path = nil

      @stored_known_values = Hash.new
      @saved_responses = Hash.new

      @templates = Hash.new

      @response = nil
    end

    attr_accessor :request_body
    attr_accessor :headers
    attr_accessor :query_params
    attr_accessor :request_path
    attr_accessor :stored_known_values
    attr_accessor :saved_responses
    attr_accessor :templates

    attr_accessor :response
  end

end