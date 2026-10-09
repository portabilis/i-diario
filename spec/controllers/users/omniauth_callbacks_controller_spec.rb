require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  # Um plugin carregado pelo Gemfile.plugins pode assinar o evento de usuário não encontrado
  # e criar o usuário; um notifier próprio deixa o spec só com os assinantes que ele registra.
  around(:each) do |example|
    original_notifier = ActiveSupport::Notifications.notifier
    ActiveSupport::Notifications.notifier = ActiveSupport::Notifications::Fanout.new

    begin
      example.run
    ensure
      ActiveSupport::Notifications.notifier = original_notifier
    end
  end

  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
    request.env['omniauth.auth'] = {
      'info' => { 'email' => email }
    }
  end

  def instrument_event_spy
    events = []
    subscriber = ActiveSupport::Notifications.subscribe(described_class::SSO_USER_NOT_FOUND_EVENT) do |*args|
      events << ActiveSupport::Notifications::Event.new(*args)
    end
    yield
    events
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  context 'when no user exists for the SSO email' do
    let(:email) { 'ninguem@portabilis.com.br' }

    it 'instruments the user-not-found event with the email and auth payload' do
      events = instrument_event_spy { get :passport }

      expect(events.size).to eq(1)
      expect(events.first.payload[:email]).to eq(email)
      expect(events.first.payload[:auth]).to eq(request.env['omniauth.auth'])
    end

    it 'redirects to the sign in page with a failure alert when nothing provisions the user' do
      get :passport

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be_present
    end

    context 'when a subscriber creates the user synchronously during the event' do
      before do
        @subscriber = ActiveSupport::Notifications.subscribe(described_class::SSO_USER_NOT_FOUND_EVENT) do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          create(:user, email: event.payload[:email], status: UserStatus::ACTIVE)
        end
      end

      after { ActiveSupport::Notifications.unsubscribe(@subscriber) }

      it 'signs the user in within the same request' do
        get :passport

        expect(controller.current_user).to be_present
        expect(controller.current_user.email).to eq(email)
      end
    end
  end

  context 'when a user already exists but is inactive' do
    let(:email) { 'inativo@portabilis.com.br' }

    before { create(:user, email: email, status: UserStatus::PENDING) }

    it 'does not instrument the user-not-found event' do
      events = instrument_event_spy { get :passport }

      expect(events).to be_empty
    end

    it 'redirects to the sign in page with a failure alert' do
      get :passport

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be_present
    end
  end

  context 'when a user already exists and is active' do
    let(:email) { 'ativo@portabilis.com.br' }

    before { create(:user, email: email, status: UserStatus::ACTIVE) }

    it 'does not instrument the user-not-found event' do
      events = instrument_event_spy { get :passport }

      expect(events).to be_empty
    end

    it 'signs the user in' do
      get :passport

      expect(controller.current_user).to be_present
      expect(controller.current_user.email).to eq(email)
    end
  end
end
