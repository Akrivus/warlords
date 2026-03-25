ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
ActiveRecord::Tasks::DatabaseTasks.migrations_paths = ["db/migrate"] if defined?(ActiveRecord::Tasks::DatabaseTasks)
require "rails/test_help"

OmniAuth.config.test_mode = true if defined?(OmniAuth)

if ActiveRecord::Base.connection.data_source_exists?("card_definitions") && CardDefinition.count.zero?
  load Rails.root.join("db/seeds.rb")
end

if ActiveRecord::Base.connection.data_source_exists?("users") && !ActiveRecord::Base.connection.column_exists?(:users, :admin)
  ActiveRecord::Base.connection.add_column(:users, :admin, :boolean)
  User.reset_column_information
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup do
      load Rails.root.join("db/seeds.rb") if ActiveRecord::Base.connection.data_source_exists?("card_definitions") && CardDefinition.count.zero?
    end

    # Add more helper methods to be used by all tests here...
    def reset_game_data!
      GameSession.update_all(current_card_id: nil)
      SessionState.delete_all if ActiveRecord::Base.connection.data_source_exists?("session_states")
      EventLog.delete_all
      SessionCard.delete_all
      GameSession.delete_all
      CardDefinition.delete_all
    end

    def create_user(email:)
      User.create!(email: email, password: "password123", password_confirmation: "password123")
    end

    def mock_oauth(provider:, uid:, email:, email_verified: true)
      auth_hash = OmniAuth::AuthHash.new(
        provider: provider.to_s,
        uid: uid,
        info: {
          email: email,
          email_verified: email_verified,
          name: "#{provider.to_s.titleize} User"
        }
      )
      OmniAuth.config.mock_auth[provider] = auth_hash
      Rails.application.env_config["omniauth.auth"] = auth_hash
    end

    def clear_oauth_mocks!
      OmniAuth.config.mock_auth = {}
      Rails.application.env_config.delete("omniauth.auth")
      Rails.application.env_config.delete("omniauth.error")
      Rails.application.env_config.delete("omniauth.error.strategy")
    end
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def create_user(email:)
    User.create!(email: email, password: "password123", password_confirmation: "password123")
  end

  def mock_oauth(provider:, uid:, email:, email_verified: true)
    auth_hash = OmniAuth::AuthHash.new(
      provider: provider.to_s,
      uid: uid,
      info: {
        email: email,
        email_verified: email_verified,
        name: "#{provider.to_s.titleize} User"
      }
    )
    OmniAuth.config.mock_auth[provider] = auth_hash
    Rails.application.env_config["omniauth.auth"] = auth_hash
  end

  def clear_oauth_mocks!
    OmniAuth.config.mock_auth = {}
    Rails.application.env_config.delete("omniauth.auth")
    Rails.application.env_config.delete("omniauth.error")
    Rails.application.env_config.delete("omniauth.error.strategy")
  end
end
