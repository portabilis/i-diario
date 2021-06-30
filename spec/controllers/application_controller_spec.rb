require 'spec_helper'

RSpec.describe ApplicationController do
  context 'password verification' do
    application = ApplicationController.new

    it 'weak_password' do
      weak_password = 'admin12345'
      password = application.instance_eval { weak_password?(weak_password) }
      expect(password).to eq(true)
    end

    it 'strong_password' do
      strong_password = '$Admin12345'
      password = application.instance_eval { weak_password?(strong_password) }
      expect(password).to eq(false)
    end
  end
end
