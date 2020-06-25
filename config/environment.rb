# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

Educacao::Application.default_url_options = Educacao::Application.config.action_mailer.default_url_options || {}
