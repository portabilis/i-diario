RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:example) do
    DatabaseCleaner.clean_with(:truncation)
  end
end