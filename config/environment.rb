# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

Educacao::Application.default_url_options = Educacao::Application.config.action_mailer.default_url_options || {}
