require 'net/http'
require 'json'

module Quiz
  #formats and sends a correct http request for a given api
  #
  #@param url [String] the url of the desired destination
  #@param token [String] the private token of the user
  #
  #@returns response [Object] from server
  def self.format_http_request(url, token)
    #converts url [string] to uri [object], needed for http::get and start methods
    uri = URI(url)
    #creates a request OBJECT with uri and token for authorization
    request = Net::HTTP::Get.new(uri, {"Authorization" => "Bearer #{token}"})

    #establishes secure http connection, closing it once request is made
    #'use_ssl :true ? as last parameter' ruby-doc says it encripts the data but idk if its needed for this project
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

  end
end
