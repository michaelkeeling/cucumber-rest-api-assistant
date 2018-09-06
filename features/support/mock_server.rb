require 'webrick'
require 'json'

class OmniServlet < WEBrick::HTTPServlet::AbstractServlet
  @@request_body = nil
  @@response_code = 200
  @@response_message = "{\"code\": \"200\", \"message\": \"success\"}"

  def do_GET (request, response)
    handle(request, response)
  end
  def do_PUT (request, response)
    handle(request, response)
  end
  def do_POST (request, response)
    handle(request, response)
  end
  def do_DELETE (request, response)
    handle(request, response)
  end

  def handle(req, res)
    @@request_body = req.body

    CucumberApiAssistant::TestLogger::debug req.unparsed_uri
    CucumberApiAssistant::TestLogger::debug req.unparsed_uri[/^.*\/(.+)\/rank$/,1]

    res.body = @@response_message
    res.status = @@response_code
  end

  def self.request_body
    @@request_body
  end
end


class MockServer
  def self.init_server
    @@request_body = nil
    @@server = nil
    @@code = 200
    @@headers = {}
    @@response_message = "success"
  end

  self.init_server

  def self.get_server
    return @@server
  end

  def self.run(port)
    self.init_server

    puts "About to start MockServer on port=#{port}"
    @@server = WEBrick::HTTPServer.new(:Port => port)
    @@server.mount '/', OmniServlet

    Thread.new do
      @@server.start
    end
  end

  def self.stop
    @@server.shutdown if @@server
    @@server = nil
  end

  def self.last_request_body
    OmniServlet.request_body
  end

end
