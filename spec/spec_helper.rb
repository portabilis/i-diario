ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'sidekiq/testing'
require 'vcr'

Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.extend VCR::RSpec::Macros
  config.mock_with :rspec
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.global_fixtures = :all
  config.infer_base_class_for_anonymous_controllers = false

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each, type: :feature) do
    fixture_path = "#{Rails.root}/spec/fixtures"
    fixtures = Dir["#{fixture_path}/**/*.yml"].map { |f| File.basename(f, '.yml') }

    ActiveRecord::FixtureSet.create_fixtures(fixture_path, fixtures)
  end
end
