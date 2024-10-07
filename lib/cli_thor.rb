# frozen_string_literal: true

require 'thor'
require 'json'
require_relative 'utils'
require_relative 'data_fetcher'
require_relative 'file_manager'

module CarmenCargo
  # CLI is a command-line interface for interacting with CarmenCargo.
  # It provides commands for navigating and downloading files.
  class CLI < Thor
    # Initializes a new instance of the CLI class.
    # It sets up a new DataFetcher instance and loads the state from a file if it exists.
    # If the state file does not exist, it initializes the path, current course ID, and current folder ID to their
    # default values.
    def initialize(*args)
      super
      @data_fetcher = DataFetcher.new('https://canvas.instructure.com/api/v1', CarmenCargo::CANVAS_TOKEN)
      @file_manager = FileManager.new

      if File.exist?('state.json')
        state = JSON.parse(File.read('state.json'))
        @path = state['path']
        @curr_course_id = state['curr_course_id']
        @curr_folder_id = state['curr_folder_id']
      else
        @path = []
        @curr_course_id = nil
        @curr_folder_id = nil
      end
    end

    # Lists the contents of the current directory.
    desc 'ls', 'List the contents in the current directory.'
    def ls
      if @path.empty?
        list_folder_names(@data_fetcher.active_courses)
      elsif @path.length == 1
        list_file_names(@data_fetcher.course_files(@curr_course_id))
        list_folder_names(@data_fetcher.course_folders(@curr_course_id))
      else
        list_file_names(@data_fetcher.folder_files(@curr_folder_id))
        list_folder_names(@data_fetcher.child_folders(@curr_folder_id))
      end
    end

    # Changes the current directory to the specified directory.
    #
    # @param directory [String] The name of the directory to change to.
    desc 'cd DIRECTORY', 'Change the current directory to DIRECTORY. Use ".." to move up one level, or "/" to go back to
    the root.'
    def cd(directory)
      if directory == '/'
        reset_state
      elsif directory == '..'
        @path.pop unless @path.empty?
      elsif (!@course_id && valid_course?(directory)) || valid_folder?(directory)
        @path.push(directory)
        update_current_path
      else
        puts 'Invalid directory name.'
      end
      save_state
    end

    # Downloads the files in the current course or folder to a specified directory.
    #
    # @param output_directory [String] The directory to download the files to. Defaults to the user's downloads folder.
    # @param types [Array<String>] The extensions of files to download.
    # @return [void]
    desc 'download [OUTPUT_DIRECTORY] [EXTENSIONS]', 'Download the files in the current course or folder to a specified
    directory. If no directory is specified, files are downloaded to the default downloads folder. Optionally, specify
    file extensions to filter which files are downloaded.'
    def download(output_directory = @file_manager.downloads_folder, *extensions)
      extensions = @file_manager.map_extension_to_mime_type(extensions)
      files = []
      if @curr_folder_id
        files = @data_fetcher.folder_files(@curr_folder_id, extensions)
      elsif @curr_course_id
        files = @data_fetcher.course_files(@curr_course_id, extensions)
      end

      files.each do |file|
        puts "Downloading #{file['display_name']}..."
        @file_manager.download_file(@data_fetcher, file, output_directory)
      end
    end

    private

    # Lists the names of the given folders.
    #
    # @param folders [Array<Hash>] The folders to list.
    def list_folder_names(folders)
      puts 'Folders:'
      folders.each do |folder|
        puts "#{folder['id']}: #{folder['name']}"
      end
      puts
    end

    # Lists the names of the given files.
    #
    # @param files [Array<Hash>] The files to list.
    def list_file_names(files)
      puts 'Files:'
      files.each do |file|
        puts file['display_name']
      end
      puts
    end

    # Resets the state of the CLI.
    def reset_state
      @path = []
      @curr_course_id = nil
      @curr_folder_id = nil
      save_state
    end

    # Saves the current state of the CLI to a file.
    def save_state
      state = {
        'path' => @path,
        'curr_course_id' => @curr_course_id,
        'curr_folder_id' => @curr_folder_id
      }
      File.write('state.json', state.to_json)
    end

    # Updates the current path based on the state of the CLI.
    def update_current_path
      if @path.empty?
        @curr_course_id = nil
        @curr_folder_id = nil
      elsif @path.length == 1
        @curr_course_id = @path[0]
        @curr_folder_id = nil
      else
        @curr_course_id = @path[0]
        @curr_folder_id = @path[-1]
      end
    end

    # Checks if the given directory is a valid course.
    #
    # @param directory [String] The directory to check.
    # @return [Boolean] Returns true if the directory is valid, false otherwise.
    def valid_course?(directory)
      active_courses = @data_fetcher.active_courses
      active_courses.any? do |course|
        course['id'].to_s == directory
      end
    end

    # Checks if the given directory is a valid folder.
    #
    # @param directory [String] The directory to check.
    # @return [Boolean] Returns true if the directory is valid, false otherwise.
    def valid_folder?(directory)
      course_folders = @data_fetcher.course_folders(@curr_course_id)
      course_folders.any? do |course|
        course['id'].to_s == directory
      end
    end
  end
end
