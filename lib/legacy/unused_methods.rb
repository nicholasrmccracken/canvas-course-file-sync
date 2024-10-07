# executes methods if choice is in the hash otherwise redirects to check for id validity
#
# @param [Hash] The has mappin choices to methods
# @param [int] either the number of an action
# @returns [Boolean] true if course is an id number
def self.perform_action(actions, course)
  if actions[course]
    actions[course].call
    false
  else
    puts "checking if #{course.to_s(16)} is a valid id..."
    true
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

  puts "Your files have been zipped and downloaded to: #{zip_file_path}"
end

def zip_multiple_files(data_fetcher, files, zipfile_name)
  Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
    files.each do |file|
      puts "Downloading \e[34m#{file['display_name']}\e[0m..."
      download_individual_file(data_fetcher, file, output_directory)
      zipfile.add(file_name, "downloads/#{file_name}")
    end
  end
end
