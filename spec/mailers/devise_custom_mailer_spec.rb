# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeviseCustomMailer, type: :mailer do
  let(:no_reply_address) { 'noreply@test.com' }
  let(:user) { create(:user) }

  before do
    allow(Entity).to receive(:current_domain).and_return('localhost')
    allow(Rails.application.secrets).to receive(:NO_REPLY_ADDRESS).and_return(no_reply_address)

    described_class.default from: "Notificação i-Diário <#{no_reply_address}>"

    ActionMailer::Base.deliveries.clear
  end

  describe '#reset_password_instructions' do
    let(:token) { 'reset-token-123' }
    let(:mail) { described_class.reset_password_instructions(user, token) }

    context 'when email domain is valid' do
      it 'sends email to user' do
        expect(mail.message.to).to include(user.email)
      end

      it 'includes IsTransactional header' do
        expect(mail.message['IsTransactional'].value).to eq('True')
      end

      it 'uses NO_REPLY_ADDRESS as from' do
        expect(mail.message.from).to include(no_reply_address)
      end
    end

    context 'when email domain is in skip list' do
      before do
        stub_const('BaseMailer::SKIP_DOMAINS', ['@blocked.com'])
        user.email = 'test@blocked.com'
      end

      it 'does not send email' do
        mail.deliver_now

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end
  end

  describe '#unlock_instructions' do
    let(:token) { 'unlock-token-123' }
    let(:mail) { described_class.unlock_instructions(user, token) }

    context 'when email domain is valid' do
      it 'sends email to user' do
        expect(mail.message.to).to include(user.email)
      end

      it 'includes IsTransactional header' do
        expect(mail.message['IsTransactional'].value).to eq('True')
      end

      it 'uses NO_REPLY_ADDRESS as from' do
        expect(mail.message.from).to include(no_reply_address)
      end
    end

    context 'when email domain is in skip list' do
      before do
        stub_const('BaseMailer::SKIP_DOMAINS', ['@blocked.com'])
        user.email = 'test@blocked.com'
      end

      it 'does not send email' do
        mail.deliver_now

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end
  end
end
