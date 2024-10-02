# frozen_string_literal: true

require 'dotenv/load'
require_relative('api_client')

module CarmenCargo
  # The DataFetcher class is responsible for fetching data from various endpoints of the API.
  # It uses the APIClient class to make the actual HTTP requests.
  #
  # @example Creating a new DataFetcher
  #   data_fetcher = CarmenCargo::DataFetcher.new('https://api.example.com', 'my_auth_token')
  class DataFetcher < APIClient
    # Fetches the current user's information.
    #
    # @return [Hash] a hash representing the current user.
    def user
      fetch_response('/users/self')
    end

    # Fetches the active courses for the current user, filtered by the latest term.
    #
    # @return [Array<Hash>] an array of hashes representing the active courses for the latest term.
    def active_courses
      params = { enrollment_type: 'student',
                 enrollment_state: 'active',
                 include: %w[term] }

      courses = fetch_paginated_response('/courses', { query: params })
      latest_term = latest_term(courses)
      courses.select do |course|
        course['term']['id'] == latest_term
      end
    end

    # Fetches the folders for a given course.
    #
    # @param course_id [Integer] the ID of the course.
    # @return [Array<Hash>] an array of hashes representing the folders for the course.
    def course_folders(course_id)
      fetch_paginated_response("/courses/#{course_id}/folders")
    end

    # Fetches all child folders for a given parent folder.
    #
    # @param folder_id [Integer] the ID of the parent folder.
    # @return [Array<Hash>] an array of hashes representing all child folders of the parent folder.
    def child_folders(folder_id)
      fetch_paginated_response("folders/#{folder_id}/folders")
    end

    # Fetches all folders for the current user.
    #
    # @return [Array<Hash>] an array of hashes representing all folders for the current user.
    def all_folders
      fetch_paginated_response('/users/self/folders')
    end

    # Fetches the files for a given course, optionally filtered by content type.
    #
    # @param course_id [Integer] the ID of the course.
    # @param content_type [Array<String>] an array of content types to filter the files by.
    # @return [Array<Hash>] an array of hashes representing the files for the course.
    def course_files(course_id, content_type = [])
      params = { content_type: content_type }
      fetch_paginated_response("/courses/#{course_id}/files", { query: params })
    end

    # Fetches the files for a given folder, optionally filtered by content type.
    #
    # @param folder_id [Integer] the ID of the folder.
    # @param content_type [Array<String>] an array of content types to filter the files by.
    # @return [Array<Hash>] an array of hashes representing the files for the folder.
    def folder_files(folder_id, content_type = [])
      params = { content_type: content_type }
      fetch_paginated_response("/folders/#{folder_id}/files", { query: params })
    end

    private

    # Determines the latest term from a list of courses.
    #
    # @param courses [Array<Hash>] an array of hashes representing the courses.
    # @return [Integer] the ID of the latest term.
    def latest_term(courses)
      latest_course = courses.max_by do |course|
        course['term']['id']
      end
      latest_course ? latest_course['term']['id'] : 0
    end
  end
end

# Test data fetcher
if __FILE__ == $PROGRAM_NAME
  data_fetcher = CarmenCargo::DataFetcher.new('https://osu.instructure.com/api/v1', ENV['CANVAS_TOKEN'])

  user = data_fetcher.user
  puts user
  puts
  courses = data_fetcher.active_courses
  puts courses
  puts
  course_folders = data_fetcher.course_folders(courses[0]['id'])
  puts course_folders
  puts
  course_files = data_fetcher.course_files(courses[0]['id'])
  puts course_files
  puts
end
