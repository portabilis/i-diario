ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/retry'
require 'sidekiq/testing'
require 'vcr'
require 'webmock/rspec'

Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Rails.application.routes.url_helpers
  config.include FixtureLoad
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = false
  config.global_fixtures = :all
  config.infer_base_class_for_anonymous_controllers = false
  config.deprecation_stream = 'log/deprecations.log'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:example, type: :feature) do
    fixture_path = "#{Rails.root}/spec/fixtures"
    fixtures = Dir["#{fixture_path}/**/*.yml"].map { |f| File.basename(f, '.yml') }
    ActiveRecord::FixtureSet.create_fixtures(fixture_path, fixtures)
  end

  config.after :each do |example|
    page.driver.restart if defined?(page.driver.restart)
  end

  config.after(:all) do
    FileUtils.rm_rf(Dir["#{Rails.root}/public/uploads/test"])
  end

  config.after :each do |example|
    page.driver.restart if defined?(page.driver.restart)
  end

  if Bullet.enable? && ENV['BULLET']
    config.before(:each) do
      Bullet.raise = true
      Bullet.start_request
    end

    config.after(:each) do
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
      Bullet.raise = false
    end
  end
end
