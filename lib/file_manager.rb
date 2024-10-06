# frozen_string_literal: true

require 'zip'

module CarmenCargo
  # FileManager is a utility class for managing file operations such as downloading and saving files.
  # It provides methods for downloading files from a given URL and saving them to a specified directory.
  #
  # @example
  #   file_manager = CarmenCargo::FileManager.new
  #   file_manager.download_file(data_fetcher, file, output_directory)
  class FileManager
    attr_reader :downloads_folder

    # Initializes a new instance of the FileManager class.
    # It sets up the downloads folder based on the operating system.
    def initialize
      @downloads_folder = case RUBY_PLATFORM
                          when /win32|win64|mingw32/ # Windows
                            File.join(ENV['USERPROFILE'], 'Downloads')
                          when /darwin/ # Mac
                            File.join(ENV['HOME'], 'Downloads')
                          else # Linux
                            File.join(ENV['HOME'], 'Downloads')
                          end
    end

    # Downloads a file from the given file hash.
    #
    # @param file [Hash] The file hash containing information for the download.
    # @param output_directory [String] The directory to download the file to.
    def download_file(data_fetcher, file, output_directory)
      file_name = file['display_name']
      FileUtils.mkdir_p(File.dirname(output_directory))
      output_path = File.join(output_directory, file_name)

      response = data_fetcher.fetch_url(file['url'])

      File.open(output_path, 'wb') do |output_file|
        output_file.write(response.body)
      end
      puts "#{file_name} downloaded to #{output_path}"
    rescue StandardError => e
      puts "Failed to download #{file_name}: #{e.message}"
    end

    # Untested Methods;

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
  end
end
