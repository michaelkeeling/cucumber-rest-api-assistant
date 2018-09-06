require 'json'
require 'securerandom'
require 'rspec/expectations'

require 'cucumber-api-assistant/test_logger'
require 'cucumber-api-assistant/request_performer'


Excon.defaults[:ssl_verify_peer] = (CucumberApiAssistant::Helpers.get_env("enable_ssl") || "true").downcase == true.to_s

LOGGER = CucumberApiAssistant::TestLogger


SPECIAL_PAYLOAD_SETTER =
  # By default, produce a new procedure which will simply set the given key to the given value
  Hash.new { |ignored_hash, missing_key| Proc.new { |hash, key, value| hash[key] = value }}
SPECIAL_PAYLOAD_SETTER.merge!(
  # But for these special values, have special behavior
  {
    "null"      => Proc.new { |hash, key, value| hash[key] = nil },
    "undefined" => Proc.new { |hash, key, value| hash.delete(key) },
    "empty"     => Proc.new { |hash, key, value| hash[key] = "" }
  }
)

SPECIAL_PAYLOAD_RETURN_VALUE_TRANSLATOR = Hash.new{ |hash, original_value| Proc.new { |context| original_value } }
SPECIAL_PAYLOAD_RETURN_VALUE_TRANSLATOR.merge!(
  {
    "null" => Proc.new { |context| nil },
    "undefined" => Proc.new { |context| nil },
    "empty" => Proc.new { |context| "" },
    "the created id" => Proc.new { |context| context.instance_variable_get(:@created_id) },
  }
)


Given /^the '(.+)' header is '(.+)'$/ do |header, value|
  @stored_rest_state.stored_known_values.each { |k, v| value = value.gsub("{" + k + "}", v) }
  @stored_rest_state.headers[header] = value
end

Given /^the '(.+)' query param is '(.*)'/ do |param, value|
  @stored_rest_state.stored_known_values.each { |k, v| value = value.gsub("{" + k + "}", v) }
  @stored_rest_state.query_params[param] = value
end

Given /^the '(.+)' query param holds the json '(.+)'/ do |param, value|
  @stored_rest_state.query_params[param] = JSON.parse(value)
end


Given /^the json REST request body is (.+)$/ do |json_str|
  raw_json_hash = JSON.parse(json_str)

  processed_json_hash = Hash.new
  raw_json_hash.map do |k, v|
    SPECIAL_PAYLOAD_SETTER[v].call(processed_json_hash, k, v)
  end

  @stored_rest_state.request_body = processed_json_hash.to_json
end


Given /^the REST request body is$/ do |any_string|
  @stored_rest_state.stored_known_values.each { |k, v| any_string = any_string.gsub("{" + k + "}", v) }
  @stored_rest_state.request_body = any_string
end



Given /^a REST key called '(.+)' has a known value$/ do |name|
  @stored_rest_state.stored_known_values[name] = Helpers.get_env(name) || name + "_" + SecureRandom.uuid
end

Given /^the value '(.+)' is saved in a REST key called '(.+)'$/ do |value, name|
  if value.downcase == "time.now"
    value = Time.now.strftime("%s")
  end

  @stored_rest_state.stored_known_values[name] = value
end


Given /^the first value for the json_path '(.+)' in the REST response is saved in a REST key called '(.+)'$/ do |json_path, name|
  values = JsonPath.new(json_path).on JSON.parse(@stored_rest_state.response.body)
  @stored_rest_state.stored_known_values[name] = values.first
end


Given /^the value of '(.+)' in the REST response is saved in a REST key called '(.+)'$/ do |value_key, key_name|
  expect(@stored_rest_state.response.body).not_to be_empty
  value = CucumberApiAssistant::Helpers.fetch_from_JSON_with_shorthand(value_key, @stored_rest_state.response.body)
  @stored_rest_state.stored_known_values[key_name] = value.to_s
end


Given /^the default endpoint template is '(.+)'$/ do |template|
  @stored_rest_state.templates[:default] = template
end


Given /^the endpoint template named '(.+)' is '(.+)'$/ do |name, template|
  @stored_rest_state.templates[name] = template
end


Given /^the REST request body contains mutipart form data from the file at '(.+)'$/ do |relative_or_absolute_path|
  if File.file?(relative_or_absolute_path)
    LOGGER.debug "Setting the contents of #{relative_or_absolute_path} as the request body."
    @stored_rest_state.headers["Content-Type"] = "multipart/form-data"
    @stored_rest_state.request_body = File.open(relative_or_absolute_path, "rb").read

  else
    LOGGER.warn "Could not find #{relative_or_absolute_path} to use as a mutipart request."
    expect(false).to be(true), "Cannot find file: #{relative_or_absolute_path}"
  end
end

Given /^the query parameters are cleared$/ do
  @stored_rest_state.query_params = Hash.new
end


When /^a (GET|POST|PATCH|PUT|DELETE) REST request is sent to the default endpoint template$/ do |verb|
  endpoint = @stored_rest_state.templates[:default]
  @stored_rest_state.stored_known_values.each { |k, v| endpoint = endpoint.gsub("{" + k + "}", v) }

  step "a #{verb} REST request is sent to '#{endpoint}'"
end

When /^a (GET|POST|PATCH|PUT|DELETE) REST request is sent to the endpoint template named '(.+)'$/ do |verb, name|
  endpoint = @stored_rest_state.templates[name]
  @stored_rest_state.stored_known_values.each { |k, v| endpoint = endpoint.gsub("{" + k + "}", v) }

  step "a #{verb} REST request is sent to '#{endpoint}'"
end



When /^a (.+) REST request is sent to the endpoint template '(.+)'$/ do |verb, template|
  endpoint = template
  @stored_rest_state.stored_known_values.each { |k, v| endpoint = endpoint.gsub("{" + k + "}", v) }
  step "a #{verb} REST request is sent to '#{endpoint}'"
end



When /^a (GET|POST|PATCH|PUT|DELETE) REST request is sent to '(.*?)'$/ do |request_verb, request_path|
  @stored_rest_state.stored_known_values.each { |k, v| request_path = request_path.gsub("{" + k + "}", v) }

  if (request_verb == "PUT")
    @stored_rest_state.response = CucumberApiAssistant::RequestPerformer.put(request_path, @stored_rest_state.headers, @stored_rest_state.request_body, @stored_rest_state.query_params)
  elsif (request_verb == "POST")
    @stored_rest_state.response = CucumberApiAssistant::RequestPerformer.post(request_path, @stored_rest_state.headers, @stored_rest_state.request_body, @stored_rest_state.query_params)
  elsif (request_verb == "PATCH")
    @stored_rest_state.response = CucumberApiAssistant::RequestPerformer.patch(request_path, @stored_rest_state.headers, @stored_rest_state.request_body, @stored_rest_state.query_params)
  elsif (request_verb == "DELETE")
    @stored_rest_state.response = CucumberApiAssistant::RequestPerformer.delete(request_path, @stored_rest_state.headers, @stored_rest_state.request_body, @stored_rest_state.query_params)
  elsif (request_verb == "GET")
    @stored_rest_state.response = CucumberApiAssistant::RequestPerformer.get(request_path, @stored_rest_state.headers, @stored_rest_state.query_params)
  else
    verb_as_string = request_verb.nil? ? "[verb not specified by the test]" : request_verb
    LOGGER.fatal("Verb #{verb_as_string} is not supported by the test suite yet.")
    raise IOError.new("Verb #{verb_as_string} is not supported by the test suite yet.")
  end
end


When /^I save the most recent REST response as '(.+)'$/ do |name|
  @stored_rest_state.saved_responses[name] = @stored_rest_state.response.body
end


Then /^the REST response code is (\d+)$/ do |code|
  expect(@stored_rest_state.response.status).to eq(code.to_i), "#{@stored_rest_state.response.status} != expected response of #{code.to_i}: #{@stored_rest_state.response.body}"
end

Then /^the '(.+)' header in the REST response is '(.+)'$/ do |header, expected_value|
  expect(@stored_rest_state.response.headers[header]).to eq(expected_value)
end

Then /^the REST response is successful$/ do
  expect(CucumberApiAssistant::RequestPerformer.response_is_success(@stored_rest_state.response)).to be_truthy, "Expected successful response, but got: Status=#{@stored_rest_state.response.status}, body=#{@stored_rest_state.response.body}"
end


Then /^the json REST response is$/ do |expected_response|
  expect(@stored_rest_state.response.body).not_to be_empty

  expected_json = JSON.parse(expected_response)
  actual_json = JSON.parse(@stored_rest_state.response.body)

  if(expected_json.is_a?(Array) and actual_json.is_a?(Array))
    expect(CucumberApiAssistant::Helpers.compare_unordered_lists(expected_json, actual_json)).to be true
  else
    expect(actual_json).to eq(expected_json)
  end

end


Then /^the json REST response matches$/ do |response_template|
  expect(@stored_rest_state.response.body).not_to be_empty

  @stored_rest_state.stored_known_values.each { |k, v| response_template.gsub!("{" + k + "}", v) }
  expected_json = JSON.parse(response_template)
  actual_json = JSON.parse(@stored_rest_state.response.body)

  if(expected_json.is_a?(Array) and actual_json.is_a?(Array))
    expect(CucumberApiAssistant::Helpers.compare_unordered_lists(expected_json, actual_json)).to be true
  else
    expect(actual_json).to eq(expected_json)
  end

end


Then /^the '(.+)' field in the REST response is the same as the value stored in the REST key '(.+)'$/ do |field, key|
  expect(@stored_rest_state.response.body).not_to be_empty
  value = CucumberApiAssistant::Helpers.fetch_from_JSON_with_shorthand(field, @stored_rest_state.response.body)
  expect(value.to_s).to eq(@stored_rest_state.stored_known_values[key])
end


Then /^the '(.+)' field in the REST response contains '(.+)'$/ do |field, expected_value|
  expect(@stored_rest_state.response.body).not_to be_empty
  value = CucumberApiAssistant::Helpers.fetch_from_JSON_with_shorthand(field, @stored_rest_state.response.body)
  expect(value.to_s).to eq(expected_value)
end


Then /^the '(.+)' json field in the REST response matches$/ do |field, expected|
  expect(@stored_rest_state.response.body).not_to be_empty
  actual_json = CucumberApiAssistant::Helpers.fetch_from_JSON_with_shorthand(field, @stored_rest_state.response.body)
  expected_json = JSON.parse(expected)

  if(expected_json.is_a?(Array) and actual_json.is_a?(Array))
   expect(CucumberApiAssistant::Helpers.compare_unordered_lists(expected_json, actual_json)).to be true
  else
    expect(actual_json).to eq(expected_json)
  end
end


Then /^the '(.+)' field in the REST response matches the expression '(.+)'$/ do |field, expected_value|
  expect(@stored_rest_state.response.body).not_to be_empty
  value = CucumberApiAssistant::Helpers.fetch_from_JSON_with_shorthand(field, @stored_rest_state.response.body)
  expect(value.to_s).to match(Regexp.new(expected_value))
end


Then /^the '(.+)' field in the REST response is empty$/ do |field|
  expect(@stored_rest_state.response.body).not_to be_empty

  value = CucumberApiAssistant::Helpers.fetch_from_JSON_with_shorthand(field, @stored_rest_state.response.body)
  expect(value.size).to eq(0)
end


Then /^the '(.+)' field in the REST response is null$/ do |field|
  expect(@stored_rest_state.response.body).not_to be_empty

  value = CucumberApiAssistant::Helpers.fetch_from_JSON_with_shorthand(field, @stored_rest_state.response.body)
  expect(value).to be_nil
end


Then /^the '(.+)' field in the REST response has a value$/ do |field|
  expect(@stored_rest_state.response.body).not_to be_empty

  value = CucumberApiAssistant::Helpers.fetch_from_JSON_with_shorthand(field, @stored_rest_state.response.body)
  expect(value.size).to be > 0
end


Then /^the '(.+)' field in the REST response has (\d+) values?$/ do |field, count|
  expect(@stored_rest_state.response.body).not_to be_empty

  value = CucumberApiAssistant::Helpers.fetch_from_JSON_with_shorthand(field, @stored_rest_state.response.body)
  expect(value.size).to eq count.to_i
end


Then /^the REST response does not contain a '(.+)' field$/ do |field|
  expect(@stored_rest_state.response.body).not_to be_empty
  exists = CucumberApiAssistant::Helpers.key_exists_in_JSON_with_shorthand(field, @stored_rest_state.response.body)
  expect(exists).to be_falsey
end
