Feature: Simple Example

  Demonstrates basic usage of the steps

  Background:
    Given the endpoint template named 'my api' is 'https://hacker-news.firebaseio.com/v0/item/{article_id}.json?print=pretty'


  Scenario: Simple GET request
    Given the 'Content-Type' header is 'application/json'
    And the 'Accept' header is 'application/json'
    When a GET REST request is sent to 'https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty'
    Then the REST response is successful
    And the REST response code is 200
    And the 'Content-Type' header in the REST response is 'application/json; charset=utf-8'


  Scenario: Requests can have dynamically set headers
    Given the value 'application/json' is saved in a REST key called 'header'
    And the 'Content-Type' header is '{header}'
    Then the 'Content-Type' header was set to 'application/json'


  Scenario: GET using the default template
    Given the default endpoint template is 'https://hacker-news.firebaseio.com/v0/item/{article_id}.json?print=pretty'
    And the value '8863' is saved in a REST key called 'article_id'
    When a GET REST request is sent to the default endpoint template
    Then the 'type' field in the REST response contains 'story'

  Scenario: Query params can be set through step functions
    Given the 'format' query param is 'json'
    And the 'date' query param is '1961:1961'
    When a GET REST request is sent to 'http://api.worldbank.org/countries/br/indicators/NY.GNP.PCAP.CD'
    Then the '1/0/date' field in the REST response contains '1961'

  Scenario: Non-string query params can be set through step functions
    Given the 'format' query param is 'json'
    And the 'date' query param is '1960:1960'
    And the 'stuff' query param holds the json '[1,2,3]'
    When a GET REST request is sent to 'http://api.worldbank.org/countries/br/indicators/NY.GNP.PCAP.CD'
    Then the '1/0/date' field in the REST response contains '1960'

  Scenario: Query params can be skipped by adding empty string initialization (helps with templated param setup)
    Given the 'format' query param is 'json'
    And the 'region' query param is 'SAS'
    And the 'lendingType' query param is ''
    When a GET REST request is sent to 'http://api.worldbank.org/countries'
    Then the '1/0/name' field in the REST response contains 'Afghanistan'

  Scenario: GET using a named template
    Given the value '8863' is saved in a REST key called 'article_id'
    When a GET REST request is sent to the endpoint template named 'my api'
    Then the 'type' field in the REST response contains 'story'


  Scenario: Check a response using a response template
    Given the value '8863' is saved in a REST key called 'article_id'
    And the value 'story' is saved in a REST key called 'article_type'
    When a GET REST request is sent to the endpoint template named 'my api'
    Then the json REST response matches
    """
    {
      "by" : "dhouston",
      "descendants" : 71,
      "id" : 8863,
      "kids" : [9224, 8952, 8917, 8884, 8887, 8943, 8869, 8940,
                8908, 8958, 9005, 8873, 9671, 9067, 9055, 8865,
                8881, 8872, 8955, 10403, 8903, 8928, 9125, 8998,
                8901, 8902, 8907, 8894, 8870, 8878, 8980, 8934, 8876],
      "score" : 104,
      "time" : 1175714200,
      "title" : "My YC app: Dropbox - Throw away your USB drive",
      "type" : "{article_type}",
      "url" : "http://www.getdropbox.com/u/2/screencast.html"
    }
    """


  Scenario: Can use shorthand for checking a nested value in a json object
    Given the value '8863' is saved in a REST key called 'article_id'
    And the value 'story' is saved in a REST key called 'article_type'
    When a GET REST request is sent to the endpoint template named 'my api'
    Then the 'kids/0' field in the REST response contains '9224'


  Scenario: Check a json response list, independent of order
    Given the value 'buzz' is saved in a REST key called 'baz_value'
    When a request is mocked with this json response
    """
      [
        1234,
        "foo",
        {
          "baz" : "buzz"
        }
      ]
    """
    Then the json REST response is
    """
      [
        {
          "baz" : "buzz"
        },
        1234,
        "foo"
      ]
    """
    And the json REST response matches
    """
      [
        {
          "baz" : "{baz_value}"
        },
        1234,
        "foo"
      ]
    """


  Scenario: Check that a json field is compared as JSON, rather than as a string
    Given the value 'buzz' is saved in a REST key called 'baz_value'
    When a request is mocked with this json response
    """
      { "starr": "ringo",
        "harrison": "george",
        "mccartney": "paul",
        "lennon": {
          "singer": "john",
          "screecher": "yoko"
        }
      }
    """
    Then the 'lennon' json field in the REST response matches
    """
      {




      "singer":"john",
        "screecher":               "yoko"


        }
    """


  Scenario: Checking a list inside a json object is order dependent
    When a request is mocked with this json response
      """
        { "list" : [1,2,3,4] }
      """
    Then the multiline args step 'the json REST response is' fails
      """
        { "list" : [2,3,4,1] }
      """


  Scenario: Checking a nested list is order dependent
    When a request is mocked with this json response
      """
        [ [1,2,3,4] ]
      """
    Then the multiline args step 'the json REST response is' fails
      """
        [ [2,3,4,1] ]
      """

  @failing
  Scenario: Use shorthand to save response values for reuse
    Given a GET REST request is sent to 'https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty'
    And the value of '0' in the REST response is saved in a REST key called 'some_identifier'
    And a GET REST request is sent to 'https://hacker-news.firebaseio.com/v0/{some_identifier}?print=pretty'
    Then the REST response is successful
    And the REST response code is 200

  Scenario: Use shorthand to test if a field is empty
    When a request is mocked with this json response
      """
        {
          "foo" : {
            "bar" : []
          }
        }
      """
    Then the 'foo/bar' field in the REST response is empty

  Scenario: Use shorthand to test if a field is not empty
    When a request is mocked with this json response
      """
        {
          "foo" : {
            "bar" : "baz"
          }
        }
    """
    Then the 'foo/bar' field in the REST response has a value


  Scenario: Use shorthand to test the size of a field
    When a request is mocked with this json response
      """
        {
          "foo" : {
            "bar" : [1, 2, 3]
          }
        }
      """
    Then the 'foo/bar' field in the REST response has 3 values


  Scenario: Use shorthand to test field equality
    When a request is mocked with this json response
      """
        {
          "foo" : {
            "bar" : "baz"
          }
        }
      """
    And the value 'baz' is saved in a REST key called 'expected_bar'
    Then the 'foo/bar' field in the REST response is the same as the value stored in the REST key 'expected_bar'


  Scenario: Request body substitions using keys
    Given the value 'foo' is saved in a REST key called 'bar'
    When the REST request body is
      """
      {
        "baz" : "{foo}",
        "foo" : "stuff"
      }
      """
    Then the request body matches
      """
      {
        "baz" : "bar",
        "foo" : "stuff"
      }
      """


  Scenario: Check for a regex match in a response field
    Given a request is mocked with this json response
      """
      {
        "details" : "Lots of details about the special failure case that took out the system."
      }
      """
    Then the 'details' field in the REST response matches the expression 'special failure case'


  Scenario: Check for a null value in a response field
    Given a request is mocked with this json response
      """
      {
        "foo" : null
      }
      """
    Then the 'foo' field in the REST response is null


  Scenario: Check for a null value in a response field using shorthand
    Given a request is mocked with this json response
      """
      {
        "foo" : [null, "not null"]
      }
      """
    Then the 'foo/0' field in the REST response is null


  Scenario: Check that a field does not exist in the response
    Given a request is mocked with this json response
      """
      {
        "foo" : "bar"
      }
      """
    Then the REST response does not contain a 'bar' field


  Scenario: Check that a field does not exist in the response with shorthand
    Given a request is mocked with this json response
      """
      {
        "foo" : {
          "notbar" : "baz"
        }
      }
      """
    Then the REST response does not contain a 'foo/bar' field


  Scenario: The provided logger is accessible
    Given I want to log some test messages


  Scenario: DELETE calls can pass a request body
    Given a mock server running on port '9876'
    And the REST request body is
      """
      {
        "plan_id" : "a man, a plan, a canal, Panama",
        "organization_guid" : "a unique organization"
      }
      """
    When a DELETE REST request is sent to 'http://localhost:9876'
    Then the REST response is successful
    And the REST response code is 200
    And the mock server received request body
      """
      {
        "plan_id" : "a man, a plan, a canal, Panama",
        "organization_guid" : "a unique organization"
      }
      """
