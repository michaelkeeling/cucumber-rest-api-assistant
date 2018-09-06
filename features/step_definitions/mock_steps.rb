require 'json'

Given /^a mock server running on port '(.+)'$/ do |port|
  MockServer.run(port.to_i)
end

Given /^the mock server received request body$/ do |expected_value|
  expect(MockServer.last_request_body).to eq(expected_value)
end

