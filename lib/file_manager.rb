# frozen_string_literal: true

require 'mime/types'
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

    # Returns the output path for a file.
    #
    # @param output_directory [String] The directory to output the file to.
    # @param file_name [String] The name of the file.
    # @return [String] The output path for the file.
    def output_path(output_directory, file_name)
      FileUtils.mkdir_p(output_directory) unless Dir.exist?(output_directory)
      File.join(output_directory, file_name)
    end

    # Writes the response body to a file.
    #
    # @param output_path [String] The path to the output file.
    # @param response [Object] The response object containing the body to write to the file.
    def write_response_to_file(output_path, response)
      File.open(output_path, 'wb') do |output_file|
        output_file.write(response.body)
      end
    end

    # Downloads a file from the given file hash.
    #
    # @param data_fetcher [Object] The object responsible for fetching the file data.
    # @param file [Hash] The file hash containing information for the download.
    # @param output_directory [String] The directory to download the file to.
    def download_individual_file(data_fetcher, file, output_directory)
      file_name = file['display_name']

      output_path = output_path(output_directory, file_name)
      response = data_fetcher.fetch_url(file['url'])

      write_response_to_file(output_path, response)

      puts "\e[32mDownload success!\e[0m"
      puts "\tFile: \e[34m#{file_name}\e[0m\n\tLocation: \e[0m\e[36m#{output_path}\e[0m\n\n"
    rescue StandardError => e
      puts "Failed to download \e[31m#{file_name}\e[0m: #{e.message}"
    end

    # Downloads multiple files.
    #
    # @param data_fetcher [Object] The object responsible for fetching the file data.
    # @param files [Array<Hash>] An array of file hashes containing information for the downloads.
    # @param output_directory [String] The directory to download the files to.
    def download_multiple_files(data_fetcher, files, output_directory)
      files.each do |file|
        puts "Downloading \e[34m#{file['display_name']}\e[0m..."
        download_individual_file(data_fetcher, file, output_directory)
      end
    end

    # Maps file extensions to their corresponding MIME types.
    #
    # @param extensions [Array<String>] An array of file extensions.
    # @return [Array<String>] An array of MIME types corresponding to the input extensions.
    def map_extension_to_mime_type(extensions)
      extensions.map do |extension|
        mime_type = MIME::Types.type_for(extension).first
        mime_type&.content_type
      end.compact
    end
  end
end
