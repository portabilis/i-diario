Devise.stretches = 1

RSpec.configure do |config|
  config.include Devise::TestHelpers, type: :controller
end
