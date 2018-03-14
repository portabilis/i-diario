require 'capybara/rspec'
require 'capybara/poltergeist'
require 'capybara-screenshot/rspec'

module Capybara
  class Session
    def ignoring_scopes
      previous_scopes = scopes.slice!(1..-1)
      yield
    ensure
      scopes.push(*previous_scopes)
    end
  end

  module DSL
    def ignoring_scopes(&block)
      page.ignoring_scopes(&block)
    end
  end
end

Capybara.configure do |config|
  config.default_driver = :poltergeist
  config.ignore_hidden_elements = true
  config.match = :prefer_exact
  config.default_max_wait_time = 5
end

Capybara.register_driver :poltergeist do |app|
  options = {
    window_size: [1920, 6000],
    timeout: 1.minute,
    phantomjs_options:['--proxy-type=none', '--load-images=no', '--ignore-ssl-errors=true']
  }
  Capybara::Poltergeist::Driver.new(app, options)
end