# frozen_string_literal: true

require 'httparty'

module CarmenCargo
  # The APIClient class is responsible for making HTTP requests to a given base URL.
  # It includes the HTTParty module, which provides a set of methods for performing HTTP requests.
  #
  # @example Creating a new APIClient
  #   api_client = CarmenCargo::APIClient.new('https://api.example.com', 'my_auth_token')
  class APIClient
    include HTTParty

    # Initializes a new APIClient.
    #
    # @param base_url [String] the base URL for the API.
    # @param auth_token [String] the authorization token for the API.
    def initialize(base_url, auth_token)
      self.class.base_uri(base_url)

      @headers = { 'Authorization' => "Bearer #{auth_token}" }
    end

    # Performs a GET request to the given endpoint and returns all the pages of the parsed response.
    # It handles pagination by continuously making requests to subsequent pages until no more data is returned.
    # If a request fails, it prints an error message.
    #
    # @param endpoint [String] the endpoint to make the GET request to.
    # @param options [Hash] additional options for the GET request.
    # @return [Array<Hash, Array>] an array of the parsed responses from all pages of the GET request, or an empty
    #   array if the request fails.
    def fetch_paginated_response(endpoint, options = {})
      all_results = []
      page = 1

      loop do
        response = fetch_response("#{endpoint}?page=#{page}", options)
        break if response.nil? || response.empty?

        all_results.concat(response)
        page += 1
      end

      all_results
    end

    # Performs a GET request to a single page of the given endpoint and returns the parsed response.
    # If the request fails, it calls the handle_error method.
    #
    # @param endpoint [String] the endpoint to make the GET request to.
    # @param options [Hash] additional options for the GET request.
    # @return [Hash, Array, nil] the parsed response from the GET request, or nil if the request fails.
    # @raise [HTTParty::Error] if an error occurs while making the GET request.
    def fetch_response(endpoint, options = {})
      response = self.class.get(endpoint, headers: @headers, **options)

      response.success? ? response.parsed_response : handle_error(endpoint, response)
    rescue HTTParty::Error => e
      puts "HTTParty Error: #{e.message}"
    end

    # Fetches the content from a given URL by performing a GET request.
    # If the request is successful, the response is returned. If the request fails,
    # it calls the `handle_error` method.
    #
    # @param file_url [String] The URL to fetch the content from.
    # @return [HTTParty::Response, nil] The response from the GET request, or nil if the request fails.
    # @raise [HTTParty::Error] If an error occurs while making the GET request.
    def fetch_url(file_url)
      response = HTTParty.get(file_url)

      response.success? ? response : handle_error(endpoint, response)
    rescue HTTParty::Error => e
      puts "HTTParty Error: #{e.message}"
    end

    private

    # Handles an error from a GET request by printing an error message.
    #
    # @param endpoint [String] the endpoint where the GET request was made.
    # @param response [HTTParty::Response] the response from the GET request.
    def handle_error(endpoint, response)
      puts "GET Request Error at #{endpoint}: #{response.code} - #{response.message}"
    end
  end
end
