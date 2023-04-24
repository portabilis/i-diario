Devise.stretches = 1

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
end
