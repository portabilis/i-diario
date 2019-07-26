RSpec.configure do |config|
  config.before(:suite) { DatabaseCleaner.clean_with(:truncation) }

  config.before(:each) { DatabaseCleaner.strategy = :transaction }
  config.before(:each) { User.current = create(:user_with_user_role) }
  config.before(:each, js: true) { DatabaseCleaner.strategy = :truncation }

  config.before(:each, type: :model) { DatabaseCleaner.start }
  config.before(:each, type: :form) { DatabaseCleaner.start }
  config.before(:each, type: :service) { DatabaseCleaner.start }
  config.before(:each, type: :controller) { DatabaseCleaner.start }
  config.before(:each, type: :worker) { DatabaseCleaner.start }

  config.after(:each, type: :model) { DatabaseCleaner.clean }
  config.after(:each, type: :form) { DatabaseCleaner.clean }
  config.after(:each, type: :service) { DatabaseCleaner.clean }
  config.after(:each, type: :controller) { DatabaseCleaner.clean }
  config.after(:each, type: :worker) { DatabaseCleaner.clean }

  config.after(:example, type: :feature) { DatabaseCleaner.clean_with(:truncation) }
end
