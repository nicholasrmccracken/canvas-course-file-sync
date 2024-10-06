module CarmenCargo
  # The FileManager class is responisble for allowing the user to browse classes and their files.
  class FileManager
    # Creates data_fetcher and user_selection class objects
    def initialize(data_fetcher)
      @data_fetcher = data_fetcher
      @user_selection = nil
    end

    # Show a quick view of all current course names
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
