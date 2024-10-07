# frozen_string_literal: true

require 'thor'
require 'json'
require_relative 'utils'
require_relative 'state_manager'
require_relative 'file_manager'
require_relative 'data_fetcher'

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
      @state_manager = StateManager.new
      @file_manager = FileManager.new
      @data_fetcher = DataFetcher.new('https://canvas.instructure.com/api/v1', CarmenCargo::CANVAS_TOKEN)

      @state_manager.load_state
    end

    # Lists the contents of the current directory.
    desc 'ls', 'List the contents in the current directory.'
    def ls
      if @state_manager.path.empty?
        list_active_courses
      elsif @state_manager.path.length == 1
        list_course_contents
      else
        list_folder_contents
      end
    end

    # Changes the current directory to the specified directory.
    #
    # @param directory [String] The name of the directory to change to.
    desc 'cd DIRECTORY', 'Change the current directory to DIRECTORY. Use ".." to move up one level, or "/" to go back to
    the root.'
    def cd(directory)
      if directory == '/'
        @state_manager.reset_state
      elsif directory == '..'
        move_up_directory
      else
        move_down_directory(directory)
      end
      @state_manager.save_state
    end

    # Downloads the files in the current course or folder to a specified directory.
    #
    # @param output_directory [String] The directory to download the files to.
    #   Defaults to the user's downloads folder.
    # @param types [Array<String>] The extensions of files to download.
    desc 'download [OUTPUT_DIRECTORY] [EXTENSIONS]', 'Download the files in the current course or folder to a specified
    directory. If no directory is specified, files are downloaded to the default downloads folder. Optionally, specify
    file extensions to filter which files are downloaded.'
    def download(output_directory = @file_manager.downloads_folder, *extensions)
      extensions = @file_manager.map_extension_to_mime_type(extensions)
      files = []
      if @state_manager.curr_folder_id
        files = @data_fetcher.folder_files(@state_manager.curr_folder_id, extensions)
      elsif @state_manager.curr_course_id
        files = @data_fetcher.course_files(@state_manager.curr_course_id, extensions)
      end

      @file_manager.download_multiple_files(@data_fetcher, files, output_directory)
    end

    private

    # Moves up one directory level by removing the last directory from the path.
    def move_up_directory
      @state_manager.path.pop unless @state_manager.path.empty?
    end

    # Moves down to a new directory by adding it to the path.
    #
    # @param directory [String] The name of the directory to move to.
    def move_down_directory(directory)
      if (!@course_id && valid_course?(directory)) || valid_folder?(directory)
        @state_manager.path.push(directory)
        @state_manager.update_state_ids
      else
        puts "\e[31mWarning error thrown\e[0m: you listed a non existent directory (\e[31m#{directory}\e[0m)"
      end
    end

    # Lists the names of the given folders.
    #
    # @param folders [Array<Hash>] The folders to list.
    def list_folder_names(folders)
      puts 'Folders:'
      folders.each do |folder|
        folder_name = folder['name']

        puts "#{folder['id']} => \e[36m#{folder_name}\e[0m"
      end
      puts
    end

    # Lists the names of the given files.
    #
    # @param files [Array<Hash>] The files to list.
    def list_file_names(files)
      puts 'Files:'
      files.each do |file|
        file_name = file['display_name']

        puts "\e[34m#{file_name}\e[0m"
      end
      puts
    end

    # Lists the names of the active courses.
    def list_active_courses
      list_folder_names(@data_fetcher.active_courses)
    end

    # Lists the contents of the current course.
    # This includes both files and folders.
    def list_course_contents
      list_file_names(@data_fetcher.course_files(@state_manager.curr_course_id))
      list_folder_names(@data_fetcher.course_folders(@state_manager.curr_course_id))
    end

    # Lists the contents of the current folder.
    # This includes both files and child folders.
    def list_folder_contents
      list_file_names(@data_fetcher.folder_files(@state_manager.curr_folder_id))
      list_folder_names(@data_fetcher.child_folders(@state_manager.curr_folder_id))
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
      course_folders = @data_fetcher.course_folders(@state_manager.curr_course_id)
      course_folders.any? do |folder|
        folder['id'].to_s == directory
      end
    end
  end
end
