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
      @token = ENV['CANVAS_TOKEN']
      return if valid_user?

      puts 'we seem to have lost your token'
      puts 'enter a new one from carmen to add it to your .env file'

      update_token
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

    # Updates the user token
    #
    # @param [String] new_token The new token to be set.
    def update_token
      new_token = gets.chomp.to_s
      @token = new_token
      ENV['TOKEN'] = new_token # Also update the .env variable if necessary
      update_env_file(new_token)
      puts 'Token updated successfully.'
    end

    def update_env_file(new_token)
      env_file_path = '.env'
      lines = File.readlines(env_file_path)

      # Prepare the content to write
      updated_lines = lines.map do |line|
        if line.start_with?('CANVAS_TOKEN=')
          "CANVAS_TOKEN=#{new_token}"
        else
          line.strip # Remove any existing newlines
        end
      end

      # Open the .env file for writing
      File.open(env_file_path, 'w') do |file|
        # Write all lines, but only append a newline to each except the last one
        updated_lines[0...-1].each do |line|
          file.puts(line)
        end
        file.print(updated_lines.last) # No newline after the last line
      end
    end

    # Validates the user by checking if the token is present
    #
    # @return [Boolean] true if valid, false otherwise
    def valid_user?
      !@token.nil? && !@token.empty?
    end

    # Fetches files for a given course ID
    #
    # @param [APIClient] api_client The API client for making requests
    # @param [Integer] course_id The ID of the course to fetch files from
    # @return [Array<Hash>] Array of file information
    def fetch_course_files(api_client, course_id)
      api_client.fetch_paginated_response("/courses/#{course_id}/files")
    end

    # Downloads a specific file by its ID
    #
    # @param [APIClient] api_client The API client for making requests
    # @param [Integer] file_id The ID of the file to download
    def download_file(api_client, file_id)
      file_info = api_client.fetch_response("/files/#{file_id}")
      if file_info && file_info['url']
        # Replace this with your actual download implementation
        puts "Downloading file: #{file_info['name']} from #{file_info['url']}"
        # Add download logic here...
      else
        puts "Error: Unable to download file with ID #{file_id}."
      end
    end
  end
end
