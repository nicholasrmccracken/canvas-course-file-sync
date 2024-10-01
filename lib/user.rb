require 'dotenv/load'
require 'net/http'
require 'json'

require_relative 'utils'

module Quiz
  # frozen_string_literal: true
  #represents a student with access to carmen
  class User
   # @return [String] name of User
   # @return [String] email of User
   # @return [String] the token for authentication
   attr_reader :name, :email, :token

    #Initialize a students data 
    # Reads user token from .env file
    #
    #@param [String] user first name
    #@param [String] user email
    def initialize(name, email)
      @name = name
      @email = email
      @token = ENV['TOKEN']
    end

    #Initialize object containing user info
    #
    #@returns [object] http response
    def parse_user_info
      #formats an http get request with url and user token
      response = Quiz.format_http_request("https://canvas.instructure.com/api/v1/users/self", @token)
      #parses and returns object into something usable
      JSON.parse(response.body)
      
    end

  end

end


#test program displaying user info to consol
#NOTE: to use user token when running use command "ruby lib/user.rb" within the proj3-cans directory 
user = Quiz::User.new("Brutus Buckeye", "buckeye.1@osu.edu")
user_info = user.parse_user_info


puts "the initialized name is brutus, but if your token is in your .env file,\n"
puts "your name is #{user_info['name']}\n"
puts "your sortable name according to carmen is #{user_info['sortable_name']}"
