ENV['RAILS_ENV'] = 'test'

require 'active_support/all'

Time.zone = 'Brasilia'

I18n.load_path += Dir['config/locales/**/*.yml']
I18n.default_locale = :'pt-BR'

$LOAD_PATH.unshift(File.expand_path('../../', __FILE__))
