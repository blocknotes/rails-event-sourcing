# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'

ENV['RAILS_ENV'] = 'test'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require File.expand_path('dummy/config/environment.rb', __dir__)

abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'pry'
require 'rspec/rails'

Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |f| require f }

# Force deprecations to raise an exception.
ActiveSupport::Deprecation.behavior = :raise

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.disable_monkey_patching!

  # Output formatter options: progress, documentation, html, json, failures
  config.formatter = ENV.fetch('RSPEC_FORMATTER', :documentation)

  # Print slow examples
  config.profile_examples = ENV['RSPEC_PROFILE'].present?

  # Abort after N failures
  config.fail_fast = ENV.fetch('RSPEC_FAILURES', 10).to_i
end
