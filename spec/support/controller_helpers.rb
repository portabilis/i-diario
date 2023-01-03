module ControllerHelpers
  def sign_in(user = double('user', id: rand(1..100)))
    if user.nil?
      allow(request.env['warden']).to receive(:authenticate!).and_throw(:warden, scope: :user)
      allow(controller).to receive_messages(current_user: nil)
    else
      allow(request.env['warden']).to receive_messages(authenticate!: user)
      allow(controller).to receive_messages(current_user: user)
    end
  end
end

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include ControllerHelpers, type: :controller
end
