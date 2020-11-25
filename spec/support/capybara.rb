require 'capybara/rspec'
require 'webdrivers/chromedriver'

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
  config.default_driver = :selenium
  config.javascript_driver = :selenium
  config.ignore_hidden_elements = true
  config.match = :prefer_exact
  config.default_max_wait_time = 10
end

Capybara.register_driver :selenium do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[headless no-sandbox disable-gpu --window-size=1024,1024]
  )
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
