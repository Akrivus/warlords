ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

if ActiveRecord::Base.connection.data_source_exists?("card_definitions") && CardDefinition.count.zero?
  load Rails.root.join("db/seeds.rb")
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def reset_game_data!
      GameSession.update_all(current_card_id: nil)
      EventLog.delete_all
      SessionCard.delete_all
      GameSession.delete_all
      CardDefinition.delete_all
    end
  end
end
