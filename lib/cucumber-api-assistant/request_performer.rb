require 'excon'
require 'certified'
require 'jsonpath'

require 'cucumber-api-assistant/helpers'
require 'cucumber-api-assistant/test_logger'
require 'cucumber-api-assistant/scenario_to_documentation_example'

module CucumberApiAssistant
  module RequestPerformer

    @@OUTPUT_SNIPPETS = (CucumberApiAssistant::Helpers.get_env("create_snippets") || "true").downcase == true.to_s

    logger = CucumberApiAssistant::TestLogger

    def self.response_is_success(response)
      response.status >= 200 && response.status <= 299
    end


    def self.throw_exception_if_not_successful(response)
      if not response_is_success(response)
        logger.fatal("HTTP error occurred:\n#{response.status}\n#{response.headers}\n#{response.body}")
        raise IOError.new("HTTP error occurred:\n#{response.status}\n#{response.headers}\n#{response.body}")
      end
    end



    def self.get(uri, headers, query_params)
      response = Excon.get(uri, :headers => headers, :query => query_params)
      
      if @@OUTPUT_SNIPPETS
        CucumberApiAssistant::ScenarioToDocumentationExample.save_get_request(uri, headers, query_params)
        CucumberApiAssistant::ScenarioToDocumentationExample.save_response(response)
      end
      
      response
    end



    # Although DELETE normally doesn't take a body, and its semantics are undefined according to
    # https://tools.ietf.org/html/rfc7231#section-4.3.5, it is occasionally necessary (e.g. Discovery Front End
    # passes client plan and organication IDs in DELETE calls for provisioning)
    #
    def self.delete(uri, headers, body, query_params)
      response = Excon.delete(uri, :headers => headers, :body => body, :query => query_params)

      if @@OUTPUT_SNIPPETS
        CucumberApiAssistant::ScenarioToDocumentationExample.save_delete_request(uri, query_params)
        CucumberApiAssistant::ScenarioToDocumentationExample.save_response(response)
      end

      response
    end



    def self.post(uri, headers, body, query_params)
      response = Excon.post(uri, :headers => headers, :body => body, :query => query_params)
      
      if @@OUTPUT_SNIPPETS
        CucumberApiAssistant::ScenarioToDocumentationExample.save_post_request(uri, headers, body, query_params)
        CucumberApiAssistant::ScenarioToDocumentationExample.save_response(response)
      end
      
      response
    end



    def self.put(uri, headers, body, query_params)
      response = Excon.put(uri, :headers => headers, :body => body, :query => query_params)
      
      if @@OUTPUT_SNIPPETS
        CucumberApiAssistant::ScenarioToDocumentationExample.save_put_request(uri, headers, body, query_params)
        CucumberApiAssistant::ScenarioToDocumentationExample.save_response(response)
      end
      
      response
    end



    def self.patch(uri, headers, body, query_params)
      response = Excon.patch(uri, :headers => headers, :body => body, :query => query_params)
      
      if @@OUTPUT_SNIPPETS
        CucumberApiAssistant::ScenarioToDocumentationExample.save_patch_request(uri, headers, body, query_params)
        CucumberApiAssistant::ScenarioToDocumentationExample.save_response(response)
      end

      response
    end

  end
end
