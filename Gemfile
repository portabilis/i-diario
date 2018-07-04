source 'https://rubygems.org'

# '~> <version>' is used to limit versions in the same release, eg: "~> 2.1" is like as ">= 2.1 and < 3.0"

ruby '2.2.6'

gem 'rails', '4.2.3'
gem 'uglifier', '>= 1.3.0'
gem 'sdoc', '~> 0.4.0', group: :doc

gem "gelf"
gem "lograge"

gem 'simple_form', '3.1.0'
gem 'pg', '0.17.1'
gem 'foreigner', '1.6.1'
gem 'devise', '3.5.1'
gem 'responders', '~> 2.0'
gem 'has_scope', '0.5.1'
gem 'enumerate_it', '1.3.1'
gem 'pundit', '0.3.0'
gem 'i18n_alchemy', '0.2.1', github: 'giustin/i18n_alchemy', branch: 'master'
gem 'cocoon', '~> 1.2.6'
gem 'jbuilder', '~> 2.2.2'
gem 'kaminari', '~> 0.16.1'
gem 'validates_timeliness', '3.0.14'
gem 'mask_validator', '0.2.1'
gem 'uri_validator'
gem "cpf_cnpj"
gem 'prawn', '~> 2.1.0', github: 'portabilis/prawn', branch: 'master'
gem 'prawn-table', '0.2.2'
gem 'audited-activerecord', git: 'https://github.com/portabilis/audited.git'
gem 'route_translator', git: 'https://github.com/enriclluelles/route_translator.git'
gem 'js-routes'
gem 'active_model_serializers'
gem 'bulk_insert', '~> 1.0'
gem 'aws-sdk', '~> 2'
gem "paperclip", "~> 5.1.0"
gem 'activerecord-tableless', '~> 2.0'

gem 'honeybadger', '~> 3.1'

gem 'angular_rails_csrf'
gem 'rack-cors', require: 'rack/cors'

gem 'sinatra', '>= 1.3.0', require: nil
gem 'sidekiq', '< 6'
gem 'sidekiq-unique-jobs', '~> 4.0.18'
gem 'whenever', require: false
gem 'rest-client', git: 'https://github.com/ricardohsd/rest-client.git'
gem 'rubyzip', '1.1.0', require: 'zip'
gem 'postgres-copy'
gem 'activerecord-session_store'

# Assets + Twitter Bootstrap
gem 'therubyracer', '0.12.2'
gem 'less-rails', '2.7.0'
gem 'twitter-bootstrap-rails', '3.2.0'
gem 'backbone-nested-attributes', git: 'git://github.com/samuelsimoes/backbone-nested-attributes.git'
gem 'handlebars_assets', '0.17.1'
gem 'ejs', '~> 1.1', '>= 1.1.1'

gem 'decore', git: 'https://github.com/matiasleidemer/decore'
gem 'activerecord-connections', git: 'https://github.com/ricardohsd/activerecord-connections.git'

gem 'carrierwave'
gem 'fog', '~> 1.36'

gem 'rdstation-ruby-client'

gem "zenvia-ruby", git: "https://github.com/portabilis/zenvia-ruby"

group :development do
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'quiet_assets'
  gem 'mina', '0.3.7'
  gem 'better_errors', '~> 1.1.0'
  gem 'binding_of_caller', '~> 0.7.2'
  gem 'puma', '~> 3.9.1'
  gem 'mina-sidekiq', '~> 0.4.1'
  gem 'web-console', '~> 2.0'
  gem 'pry-byebug'
  gem 'pry-remote'
end

group :test do
  gem 'business_time'
  gem 'turnip', '~> 1.3', '>= 1.3.1'
  gem 'capybara', '~> 2.5'
  gem 'poltergeist', '~> 1.8.1'
  gem 'shoulda-matchers', '~> 3.0', '>= 3.0.1'
  gem 'vcr', '~> 3.0'
  gem 'webmock', '~> 1.22', '>= 1.22.3'
  gem 'database_cleaner', '~> 1.5', '>= 1.5.1'
  gem 'pdf-inspector', require: 'pdf/inspector'
  gem 'capybara-screenshot'
  gem 'rspec-rails', '~> 3.4'
  gem 'factory_girl_rails', '~> 4.5'
  gem 'pry', '~> 0.10.3'
  gem 'faker', '~> 1.6', '>= 1.6.1'
  gem 'cpf_faker', '~> 1.3'
  gem 'timecop'
  gem 'simplecov', :require => false
end

group :test, :development do
  gem 'bullet'
end

gem 'newrelic_rpm'
