require 'shellwords'
require 'fileutils'
require 'cgi'

require 'cucumber-api-assistant/helpers'
require 'cucumber-api-assistant/test_logger'

# This module records a given request and/or response in AsciiDoc notation. In
# this way, we can generate documentation snippets from actual test cases +
# actual service requests/responses.

DOCUMENTATION_DIRECTORY_ROOT = CucumberApiAssistant::Helpers.get_env("snippets_dir") || ".."
DOCUMENTATION_OUTPUT_DIRECTORY = File.join(DOCUMENTATION_DIRECTORY_ROOT, "documentation", "snippets")

Before do |scenario|
  CucumberApiAssistant::ScenarioToDocumentationExample.prepare_for_new_scenario(scenario)
end


STATUS_CODES = Hash.new { |code| "" }
STATUS_CODES[200] = "OK"
STATUS_CODES[201] = "CREATED"

module CucumberApiAssistant

  module ScenarioToDocumentationExample

    module HttpVerbs
      DELETE = "DELETE"
      GET = "GET"
      HEAD = "HEAD"
      POST = "POST"
      PUT = "PUT"
      PATCH = "PATCH"
    end


    @@scenario = nil

    @@logger = CucumberApiAssistant::TestLogger

    def self.prepare_for_new_scenario(scenario)
      @@scenario = scenario
      @@request_number = 1
    end

    def self.save_response(response)
      response_headers = response.headers.map { |header_name, header_value|
        "#{header_name}: #{header_value}"
      }.join("\n")

      #Include status code and human-friendly response name, if available
      status_pretty = "#{response.status} #{STATUS_CODES[response.status]}"

      response_text = <<EOT
HTTP 1.1 #{status_pretty}
#{response_headers}

#{response.body}
EOT

      @@logger.debug response_text

      response_pretty = <<EOT
[source,http]
----
#{response_text}
----
EOT
      self.save_documentation_example('response', response_pretty)

      @@request_number = @@request_number + 1
    end


    def self.save_get_request(uri, headers = {}, query_params = {})
      self.save_request(uri, HttpVerbs::GET, headers, query_params)
    end


    def self.save_delete_request(uri, headers = {}, query_params = {})
      self.save_request(uri, HttpVerbs::DELETE, headers, query_params)
    end


    def self.save_head_request(uri, headers = {}, body = "", query_params = {})
      self.save_request(uri, HttpVerbs::HEAD, headers, query_params, body)
    end


    def self.save_post_request(uri, headers = {}, body = "", query_params = {})
      self.save_request(uri, HttpVerbs::POST, headers, query_params, body)
    end


    def self.save_put_request(uri, headers = {}, body = "", query_params = {})
      self.save_request(uri, HttpVerbs::PUT, headers, query_params, body)
    end


    def self.save_patch_request(uri, headers = {}, body = "", query_params = {})
      self.save_request(uri, HttpVerbs::PATCH, headers, query_params, body)
    end



    def self.save_request(uri, verb, headers = {}, query_params= {}, body = "")

      header_flags = headers.map { |header_name, header_value|
        header_flag = "#{header_name}: #{header_value}"
        "-H '#{header_flag}'"
      }.join(" ")
      header_flags = " " + header_flags

      case verb.downcase
      when HttpVerbs::GET
        #Curl's default verb
        verb_pretty = ""
      when HttpVerbs::HEAD
        verb_pretty = "-I"
      else
          verb_pretty = "-X #{verb.upcase}"
      end
      verb_pretty = " #{verb_pretty}"

      if body != ""
        body_pretty = " -d \\\n'#{body}'"
      else
        body_pretty = ''
      end

      if !query_params.empty?
        uri += '?'
        uri += query_params.map { |k, v| k.to_s + "=" + CGI.escape(v.to_s) }.join("&")
      end

      request_text = "curl -i#{verb_pretty}#{header_flags} '#{uri}'#{body_pretty}"

      @@logger.debug request_text

      request_example = <<EOT
[source,bash]
----
#{request_text}
----
EOT
      self.save_documentation_example('request', request_example)
    end

    def self.save_documentation_example(type, content)
      output = documentation_file_name(type)

      begin
        FileUtils.mkpath File.dirname(output)
      rescue Errno::EEXIST
        #Directory already exists? Awesome. Someone did the work already!
      end

      File.open(output, 'w') { |file|
        file.write(content)
      }
    end

    def self.documentation_file_name(suffix)
      scenario_name = @@scenario.name.downcase
      sub_pairs = {
        ' ' => '_',
        '#' => '',
        ',' => '_',
        '(' => '',
        ')' => '',
        '__' => '_'
      }

      sub_pairs.each { |from, to| scenario_name = scenario_name.gsub(from, to) }
      File.join(DOCUMENTATION_OUTPUT_DIRECTORY, scenario_name, @@request_number.to_s, suffix + ".adoc")
    end
  end
end
