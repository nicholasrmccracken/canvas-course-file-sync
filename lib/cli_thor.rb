# frozen_string_literal: true

require 'thor'
require 'json'
require 'zip'
require_relative 'utils'
require_relative 'data_fetcher'

module CarmenCargo
  class CLI < Thor
    # Creates user and api objects as well as maps to user info and classes
    def initialize(*args)
      super
      @data_fetcher = DataFetcher.new('https://canvas.instructure.com/api/v1', CarmenCargo::CANVAS_TOKEN)

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
    desc 'ls', 'List the files in the current directory.'
    def ls
      if @path.empty?
        list_item_names(@data_fetcher.active_courses, 'name')
      elsif @path.length == 1
        list_item_names(@data_fetcher.course_folders(@curr_course_id), 'name')
        list_item_names(@data_fetcher.course_files(@curr_course_id), 'display_name')
      else
        list_item_names(@data_fetcher.child_folders(@curr_folder_id), 'name')
        list_item_names(@data_fetcher.folder_files(@curr_folder_id), 'display_name')
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
      elsif valid_directory?(directory)
        @path.push(directory)
        update_current_path
      else
        puts 'Invalid directory name.'
      end
      save_state
    end

    # Downloads the files in the current course or folder to a specified directory.
    #
    # @param output_directory [String] The directory to download the files to. Defaults to the value of user's downloads
    #   folder.
    # @param types [Array<String>] The types of files to download.
    # @return [void]
    desc 'download [OUTPUT_DIRECTORY] [TYPES]', 'Download the files in the current course or folder to a specified
    directory. If no directory is specified, files are downloaded to the default downloads folder. Optionally, specify
    file types to filter which files are downloaded.'
    def download(output_directory = downloads_folder, *types)
      files = []
      if @curr_folder_id
        files = @data_fetcher.folder_files(@curr_folder_id, types)
      elsif @curr_course_id
        files = @data_fetcher.course_files(@curr_course_id, types)
      end

      files.each do |file|
        puts "Downloading #{file['display_name']}..."
        download_file(file, output_directory)
      end
    end

    private

    def reset_state
      @path = []
      @curr_course_id = nil
      @curr_folder_id = nil
      save_state
    end

    def save_state
      state = {
        'path' => @path,
        'curr_course_id' => @curr_course_id,
        'curr_folder_id' => @curr_folder_id
      }
      File.write('state.json', state.to_json)
    end

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

    def valid_directory?(directory)
      course_ids = @data_fetcher.active_courses.map do |course|
        course['id'].to_s
      end
      return course_ids.include?(directory) unless @course_id

      folder_ids = @data_fetcher.course_folders(@curr_course_id).map do |folder|
        folder['id'].to_s
      end

      course_ids.include?(directory) || folder_ids.include?(directory)
    end

    def list_children(folders, files)
      folders.each do |folder|
        puts folder['name']
      end
      files.each do |file|
        puts file['name']
      end
    end

    def list_item_names(items, name)
      items.each do |item|
        puts "#{item['id']}: #{item[name]}"
      end
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
        download_file(file)
      end
    end

    # Downloads a file from the given file hash.
    #
    # @param [Hash] file The file hash containing information for the download.
    def download_file(file, output_directory)
      file_name = file['display_name']
      FileUtils.mkdir_p(File.dirname(output_directory))
      output_path = File.join(output_directory, file_name)

      response = @data_fetcher.fetch_url(file['url'])

      File.open(output_path, 'wb') do |output_file|
        output_file.write(response.body)
      end
      puts "#{file_name} downloaded to #{output_path}"
    rescue StandardError => e
      puts "Failed to download #{file_name}: #{e.message}"
    end

    def downloads_folder
      case RUBY_PLATFORM
      when /win32|win64|mingw32/ # Windows
        File.join(ENV['USERPROFILE'], 'Downloads')
      when /darwin/ # Mac
        File.join(ENV['HOME'], 'Downloads')
      else # Linux
        File.join(ENV['HOME'], 'Downloads')
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
  end
end
