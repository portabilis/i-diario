require 'capybara/rspec'
require 'capybara/poltergeist'

Capybara.configure do |config|
  config.default_driver = :poltergeist
  config.app_host = 'http://lvh.me'
  config.server_port = 45000
  config.ignore_hidden_elements = true
end
