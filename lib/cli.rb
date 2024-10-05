# frozen_string_literal: true

require_relative 'user'
require_relative 'api_client'
require_relative 'utils'
require_relative 'data_fetcher'

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
      else
        puts "the ID you entered is not one of the ones listed above.\n"
      end
    end

    # Exits the program with a goodbye message.
    def exit_program
      puts "It's been fun seeing you!"
      exit
    end
  end
end

cli = CarmenCargo::CLI.new
cli.start_program
