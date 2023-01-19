require_relative 'boot'

require 'csv'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Educacao
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.eager_load_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('app/workers')
    config.eager_load_paths << Rails.root.join('app/workers/ieducar')
    config.eager_load_paths << Rails.root.join('app/workers/concerns')
    config.eager_load_paths << Rails.root.join('app/workers/student_dependencies_discarders')
    config.eager_load_paths << Rails.root.join('app/services')
    config.eager_load_paths << Rails.root.join('app/services/ieducar_synchronizers')
    config.eager_load_paths << Rails.root.join('app/queries')

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Brasilia'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.load_path += Dir["#{config.root}/config/locales/**/*.yml"]
    config.i18n.default_locale = :"pt-BR"

    config.active_record.schema_format = :sql

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :options]
      end
    end
    config.to_prepare do
      DeviseController.respond_to :html, :json
    end
  end
end
