# frozen_string_literal: true

require_relative 'user'
require_relative 'api_client'
require_relative 'utils'
require_relative 'data_fetcher'
require 'zip'

module CarmenCargo
  # class for handling command line issues
  class CLI
    # @return [Object] User for a given token
    # @return [Object] api client for given url + token
    # @return [Map] user information (thumbprint), contains name and student id
    # @return [Map] course list for student to select class
    attr_reader :user, :api_client, :thumbprint, :class_list

    # Creates user and api objects as well as maps to user info and classes
    def initialize
      @user = CarmenCargo::User.new
      @api_client = CarmenCargo::APIClient.new('https://canvas.instructure.com/api/v1', user.token)

      @thumbprint = user.make_thumbprint(@api_client)
      @course_map = user.get_user_classes(@api_client)
    end

    # Displays the welcome message and handles user choice for navigation
    def start_program
      puts "Hello #{@thumbprint[:name]}, #{File.read('resources/intro.txt')}"

      actions = { -1 => -> { exit_program },
                  -2 => -> { user.print_user_classes(@course_map) } }

      loop do
        puts 'Please enter the course ID you would like to download files from, or enter -1 to exit, or -2 to view classes.'
        course = gets.chomp.to_i(16)
        is_id = CarmenCargo.perform_action(actions, course)
        get_class_files(course) if is_id
      end
    end

    # compares course_num against @course_map, goes to create class specific call if true
    #
    # @param [int] a number in decimal form representing a course ID
    def get_class_files(course_num)
      if @course_map.value?(course_num)
        # go download files
        data_fetcher = CarmenCargo::DataFetcher.new('https://canvas.instructure.com/api/v1', user.token)
        files = data_fetcher.course_files(course_num)

        download_files(files) # Calls the method to handle file downloads
      else
        puts "the ID you entered is not one of the ones listed above.\n"
      end
    end

    # Prompt user for the output file path
    def prompt_for_output_file_path
      loop do
        puts "\nEnter the output file path to save the downloaded file (or 'quit' to exit):"
        path = gets.chomp

        break if path.downcase == 'quit'

        if valid_path?(path)
          @output_path = path
          puts "Output path set to: #{@output_path}"
          break
        else
          puts 'Invalid path. Please try again.'
        end
      end
    end

    # Validate if the provided file path is valid
    def valid_path?(path)
      Dir.exist?(File.dirname(path))
    end

    # Downloads files from the given array of file hashes.
    #
    # @param [Array<Hash>] files The array of file hashes to download.
    def download_files(files)
      files.each do |file|
        # Logic for downloading file, e.g., save to a specific directory
        puts "Downloading #{file['name']}..."
        download_file(file)
      end
      puts 'Download completed.'
    end

    # Downloads a file from the given file hash.
    #
    # @param [Hash] file The file hash containing information for the download.
    def download_file(file)
      file_url = file['url'] # Adjust this key based on the API response
      file_name = file['name']

      uri = URI(file_url)
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        File.open("downloads/#{file_name}", 'wb') do |f|
          f.write(response.body)
        end
        puts "Downloaded #{file_name}."
      else
        puts "Failed to download #{file_name}: #{response.code} #{response.message}"
      end
    end

    # Zips the downloaded files and saves them in the downloads directory.
    #
    # @param [Array<String>] files The array of file names to zip.
    def zip_files(files)
      zip_file_name = "downloads/#{Time.now.strftime('%Y%m%d%H%M%S')}_downloads.zip"

      Zip::File.open(zip_file_name, Zip::File::CREATE) do |zipfile|
        files.each do |file_name|
          zipfile.add(file_name, "downloads/#{file_name}")
        end
      end

      show_zip_download_info(zip_file_name) # Show zip file download info
    end

    # Shows the user what files have been fetched
    #
    # @param fetched_files [Array<String>] The list of fetched files
    def show_fetched_files(fetched_files)
      puts 'Fetched Files:'
      if fetched_files.empty?
        puts 'No files have been fetched.'
      else
        fetched_files.each do |file|
          puts "- #{file}"
        end
      end
    end

    # Shows user the name and file path of the downloaded zip
    #
    # @param zip_file_path [String] The path of the downloaded zip file
    def show_zip_download_info(zip_file_path)
      puts "Your files have been zipped and downloaded to: #{zip_file_path}"
    end

    # Checks the file type of a given file
    #
    # @param file_path [String] The path of the file to check
    # @return [String, nil] The file type if valid, nil otherwise
    def check_file_type(file_path)
      if File.exist?(file_path)
        file_extension = File.extname(file_path)
        valid_extensions = ['.pdf', '.docx', '.pptx', '.txt', '.csv'] # Add valid file types as needed

        return file_extension if valid_extensions.include?(file_extension)

        puts "Invalid file type: #{file_extension}. Please select a valid file type."
        nil

      else
        puts "File does not exist at: #{file_path}"
        nil
      end
    end

    # Exits the program with a goodbye message.
    def exit_program
      puts "It's been fun seeing you!"
      exit
    end

    def show_courses
      courses = @data_fetcher.active_courses
      puts 'Active Courses:'
      courses.each_with_index do |course, index|
        puts "#{index + 1} - #{course['name']}"
      end
    rescue StandardError => e
      puts "Error fetching courses: #{e.message}"
    end

    # Show a quick view of all files of chosen course
    def show_course_files(course_id)
      files = @data_fetcher.course_files(course_id)
      puts 'Course files:'
      files.each_with_index do |file, index|
        puts "#{index + 1} - #{file['name']}"
      end
    rescue StandardError => e
      puts "Error fetching course files: #{e.message}"
    end

    # Show a quick view of all course folders
    def show_course_folders(course_id)
      folders = @data_fetcher.course_folders(course_id)
      puts 'Courses folders:'
      folders.each_with_index do |folder, index|
        puts "#{index + 1} - #{folder['name']}"
      end
    rescue StandardError => e
      puts "Error fetching folders: #{e.message}"
    end

    # Show a quick view of all course folders
    def show_user_folders
      folders = @data_fetcher.all_folders
      puts 'All folders:'
      folders.each_with_index do |folder, index|
        puts "#{index + 1} - #{folder['name']}"
      end
    rescue StandardError => e
      puts "Error fetching all folders: #{e.message}"
    end

    # Show a quick view of all child files
    def show_child_files(folder_id)
      files = @data_fetcher.folder_files(folder_id)
      puts 'All child files:'
      files.each_with_index do |file, index|
        puts "#{index + 1} - #{file['name']}"
      end
    rescue StandardError => e
      puts "Error fetching files: #{e.message}"
    end

    # Prompt user to select a course.
    # Loop until user choice is valid.
    def prompt_user_for_course
      loop do
        puts "\nEnter the number of the course you want to view/download from (or 'quit' to exit):"
        input = gets.chomp

        break if input.downcase == 'quit' # if user wants to quit, break out

        if valid_course_selection?(input)
          @user_selection = input.to_i - 1
          break
        else
          puts 'Invalid selection. Please try again.'
        end
      end
    end

    # Prompt user to select a course folder.
    # Loop until user choice is valid.
    def prompt_user_for_course_folder
      loop do
        puts "\nEnter the number of the folder you want to view/download from (or 'quit' to exit):"
        input = gets.chomp

        break if input.downcase == 'quit' # if user wants to quit, break out

        if valid_course_folder_selection?(input)
          @user_selection = input.to_i - 1
          break
        else
          puts 'Invalid selection. Please try again.'
        end
      end
    end

    # Prompt user to select a course file.
    # Loop until user choice is valid.
    def prompt_user_for_course_file
      loop do
        puts "\nEnter the number of the file you want to view/download from (or 'quit' to exit):"
        input = gets.chomp

        break if input.downcase == 'quit' # if user wants to quit, break out

        if valid_course_file_selection?(input)
          @user_selection = input.to_i - 1
          break
        else
          puts 'Invalid selection. Please try again.'
        end
      end
    end

    # Prompt user to select a user folder.
    # Loop until user choice is valid.
    def prompt_user_for_user_folder
      loop do
        puts "\nEnter the number of the user folder you want to view/download from (or 'quit' to exit):"
        input = gets.chomp

        break if input.downcase == 'quit' # if user wants to quit, break out

        if valid_user_file_selection?(input)
          @user_selection = input.to_i - 1
          break
        else
          puts 'Invalid selection. Please try again.'
        end
      end
    end

    # Prompt user to select a folder file.
    # Loop until user choice is valid.
    def prompt_user_for_folder_file
      loop do
        puts "\nEnter the number of the folder file you want to view/download from (or 'quit' to exit):"
        input = gets.chomp

        break if input.downcase == 'quit' # if user wants to quit, break out

        if valid_folder_file_selection?(input)
          @user_selection = input.to_i - 1
          break
        else
          puts 'Invalid selection. Please try again.'
        end
      end
    end

    # Prompt user to select a file type, if any
    def prompt_for_file_type
      loop do
        puts "\nEnter the file type you want to download (e.g., all, pdf, docx) or 'quit' to exit:"
        input = gets.chomp

        break if input.downcase == 'quit'

        if valid_file_type?(input) || input.downcase == 'all'
          @file_type = input
          break
        else
          puts 'Invalid file type. Please try again.'
        end
      end
    end

    # Download file from the selected course/folder
    def download_file
      if @user_selection.nil?
        puts 'No valid course/folder selected. Cannot download.'
        return
      end

      course_or_folder = @data_fetcher.fetch_course_or_folder(@user_selection)
      files = course_or_folder['files'].select { |file| file['type'] == @file_type }

      if files.empty?
        puts "No files of type #{@file_type} found."
        return
      end

      # Download files and save to the specified output path
      files.each do |file|
        content = @data_fetcher.download_file(file['url'])
        File.write(File.join(@output_path, file['name']), content)
        puts "Downloaded #{file['name']} to #{@output_path}"
      rescue StandardError => e
        puts "Error downloading file: #{e.message}"
      end
    end

    private

    # Check if the selected course option is valid
    def valid_course_selection?(input)
      input.to_i.positive? && input.to_i <= @data_fetcher.active_courses.size
    end

    # Check if the selected course folder option is valid
    def valid_course_folder_selection?(input, course_id)
      input.to_i.positive? && input.to_i <= @data_fetcher.course_folder(course_id).size
    end

    # Check if the selected file option is valid
    def valid_course_file_selection?(input, course_id)
      input.to_i.positive? && input.to_i <= @data_fetcher.course_files(course_id).size
    end

    # Check if the selected user folder option is valid
    def valid_user_folder_selection?(input)
      input.to_i.positive? && input.to_i <= @data_fetcher.all_folders.size
    end

    # Check if the selected folder file option is valid
    def valid_folder_file_selection?(input, folder_id)
      input.to_i.positive? && input.to_i <= @data_fetcher.folder_files(folder_id).size
    end

    # Validate the file type (you could expand this with more logic)
    def valid_file_type?(input)
      %w[pdf docx txt].include?(input.downcase)
    end
  end
end

cli = CarmenCargo::CLI.new
cli.start_program
