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

  def connect_to_entity
    entity = Entity.find_by(domain: 'test.host').send(:connection_spec)
    ActiveRecord::Base.establish_connection(entity)
  end
end

RSpec.configure do |config|
  config.include Devise::TestHelpers, type: :controller
  config.include ControllerHelpers, type: :controller
end
