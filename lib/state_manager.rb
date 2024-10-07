# frozen_string_literal: true

require 'json'

module CarmenCargo
  # The StateManager class is responsible for managing the state of the application.
  # It loads the state from a file when initialized, and provides methods to reset and save the state.
  class StateManager
    attr_reader :path, :curr_course_id, :curr_folder_id

    # Initializes a new instance of the StateManager class.
    #
    # @param file_path [String] The path to the file from which to load the state.
    #   Defaults to 'state.json'.
    def initialize(file_path = 'state.json')
      @file_path = file_path

      load_state
    end

    # Loads the state from the file.
    # If the file does not exist, initializes the state to its default values.
    def load_state
      if File.exist?(@file_path)
        state = JSON.parse(File.read(@file_path))
        @path = state['path']
        @curr_course_id = state['curr_course_id']
        @curr_folder_id = state['curr_folder_id']
      else
        @path = []
        @curr_course_id = nil
        @curr_folder_id = nil
      end
    end

    # Resets the state of the program back to the root directory.
    def reset_state
      @path = []
      @curr_course_id = nil
      @curr_folder_id = nil
      save_state
    end

    # Saves the current state to a file.
    # The state is saved as a hash with keys 'path', 'curr_course_id', and 'curr_folder_id'.
    def save_state
      state = {
        'path' => @path,
        'curr_course_id' => @curr_course_id,
        'curr_folder_id' => @curr_folder_id
      }
      File.write('state.json', state.to_json)
    end

    # Updates the current course and folder IDs based on the current path.
    def update_state_ids
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
  end
end
