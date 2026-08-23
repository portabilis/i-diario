require 'rails_helper'

RSpec.describe ThreadContextResetRackMiddleware do
  let(:entity) { create(:entity, name: 'Rack', domain: 'rack.reset.test') }
  let(:env) { {} }

  def middleware(&app)
    described_class.new(app || ->(_env) { [200, {}, ['ok']] })
  end

  it 'resets Entity.current, User.current and origin_type after the request' do
    app = middleware do |_env|
      Entity.current = entity
      User.current = create(:user)
      Thread.current[:origin_type] = OriginTypes::WEB
      [200, {}, ['ok']]
    end

    app.call(env)

    expect(Entity.current).to be_nil
    expect(User.current).to be_nil
    expect(Thread.current[:origin_type]).to be_nil
  end

  it 'resets the context when a controller skips handle_customer and leaves the tenant set' do
    # Cenário do Api::V2::EntitiesController do engine: pula o handle_customer
    # e chama current_entity, que seta Entity.current como efeito colateral.
    app = middleware do |_env|
      Entity.current = entity
      [200, {}, ['ok']]
    end

    app.call(env)

    expect(Entity.current).to be_nil
  end

  it 'resets the context even when the request raises' do
    app = middleware { |_env| raise 'boom' }

    expect { app.call(env) }.to raise_error('boom')

    expect(Entity.current).to be_nil
    expect(User.current).to be_nil
    expect(Thread.current[:origin_type]).to be_nil
  end

  it 'starts the request with a clean context even when the thread inherited one' do
    Entity.current = entity

    seen_inside = :unset
    middleware { |_env| seen_inside = Entity.current; [200, {}, ['ok']] }.call(env)

    expect(seen_inside).to be_nil
  end

  it 'isolates two sequential requests on the same thread' do
    middleware { |_env| Entity.current = entity; [200, {}, ['ok']] }.call(env)

    second_request_context = :unset
    middleware { |_env| second_request_context = Entity.current; [200, {}, ['ok']] }.call(env)

    expect(second_request_context).to be_nil
  end

  it 'returns the response untouched' do
    response = middleware.call(env)

    expect(response).to eq([200, {}, ['ok']])
  end

  describe 'stack registration' do
    let(:middlewares) { Rails.application.middleware.map(&:name) }

    it 'runs outside the controller stack' do
      expect(middlewares).to include(described_class.name)
    end

    # A posição relativa é o que dá valor ao middleware, e duas inserções em
    # insert_before 0 (esta e a do Rack::Cors) tornam a ordem dependente da
    # sequência das linhas em config/application.rb. Sem esta asserção, uma
    # reordenação passaria despercebida e os reports de exceção chegariam ao
    # Honeybadger sem a tag de tenant.
    it 'runs below the Honeybadger error notifier, so the report still sees the tenant' do
      reset_index = middlewares.index(described_class.name)
      notifier_index = middlewares.index('Honeybadger::Rack::ErrorNotifier')

      expect(notifier_index).not_to be_nil
      expect(reset_index).to be > notifier_index
    end
  end
end
