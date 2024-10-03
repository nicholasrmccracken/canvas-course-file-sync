# frozen_string_literal: true

require 'dotenv'
require 'net/http'
require 'json'

Dotenv.load(File.expand_path('../.env', __dir__))

require_relative 'api_client'

module CarmenCargo
  # Represents a student with access to Carmen
  class User
    # @return [String] name of User
    # @return [String] email of User
    # @return [String] the token for authentication
    attr_reader :token

    # Initialize a students data
    # Reads user token from .env file
    #
    # @param [String] user first name
    # @param [String] user email
    def initialize
      @token = ENV['TOKEN']
    end

    # Creates a Map with users name and given id number
    #
    # @param api_client
    # @return a map with the users full name and id number
    def make_thumbprint(api_client)
      user_info = api_client.fetch_response('/users/self')
      if user_info
        { name: user_info['name'], id: user_info['id'] }
      else
        puts "error: could not save #{user_info['name']}'s carmen ID number"
      end
    end

    # Prints out the users name and carmen id values
    #
    # @param [Map] holds user name and id
    def print_user_info(thumbprint)
      puts "Name: #{thumbprint[:name]}"
      puts "ID: #{thumbprint[:id]}"
    end

    # creates a Map with complete list of user classes and course id
    #
    # @param api_client for creating call for course list
    # @returns [Map] with key as the course name and value as its id
    def get_user_classes(api_client)
      course_map = {}
      courses = api_client.fetch_paginated_response('/courses')
      courses.each do |course|
        course_map[course['name']] = course['id']
      end
      course_map
    end

    # prints the map with the users class list
    #
    # @param [Map] course lsit with names and id
    def print_user_classes(course_map)
      course_map.each do |class_name, class_id|
        puts "** Class Name: #{class_name}\n**\t\e[34mClass ID:#{class_id.to_s(16)}\e[0m\n\n"
      end
    end
  end
end
