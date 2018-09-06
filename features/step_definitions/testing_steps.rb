require 'excon'

Given /^I want to log some test messages$/ do
  LOGGER.debug("debug works")
  LOGGER.warn("warn works")
  LOGGER.fatal("fatal works")
  LOGGER.error("error works")
  LOGGER.info("info works")
end

Then /^the multiline args step '(.+)' fails$/ do |step, lines|
  it_did_fail = false
  begin
    step "#{step}", lines
  rescue RSpec::Expectations::ExpectationNotMetError => e
    it_did_fail = true
  end
  expect(it_did_fail).to be true
end

When /^a request is mocked with this json response$/ do |json_response|
	@stored_rest_state.response = Excon::Response.new
	@stored_rest_state.response.body = json_response
end

Then /^the request body matches$/ do |expected|
  @request = JSON.parse(expected)
end

Then /^the '(.+)' header was set to '(.+)'$/ do |header, expected_value|
  expect(@stored_rest_state.headers[header]).to eq(expected_value)
end
