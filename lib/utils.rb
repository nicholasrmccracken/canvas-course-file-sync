# frozen_string_literal: true

# Module for carmen download program
module CarmenCargo
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
end
