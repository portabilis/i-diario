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

  context 'email validation for notifications' do
    application = ApplicationController.new

    it 'returns false for blank email' do
      result = application.instance_eval { valid_email_for_notification?('') }
      expect(result).to eq(false)
    end

    it 'returns false for nil email' do
      result = application.instance_eval { valid_email_for_notification?(nil) }
      expect(result).to eq(false)
    end

    it 'returns false for @ambiente.portabilis email' do
      result = application.instance_eval { valid_email_for_notification?('test@ambiente.portabilis') }
      expect(result).to eq(false)
    end

    it 'returns true for valid email' do
      result = application.instance_eval { valid_email_for_notification?('user@example.com') }
      expect(result).to eq(true)
    end
  end
end
