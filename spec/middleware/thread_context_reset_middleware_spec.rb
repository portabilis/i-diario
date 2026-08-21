require 'rails_helper'

RSpec.describe ThreadContextResetMiddleware do
  subject(:middleware) { described_class.new }

  let(:entity) { create(:entity, name: 'Middleware', domain: 'middleware.reset.test') }

  it 'resets Entity.current, User.current and origin_type after the job' do
    middleware.call(nil, {}, 'default') do
      Entity.current = entity
      User.current = create(:user)
      Thread.current[:origin_type] = OriginTypes::WEB
    end

    expect(Entity.current).to be_nil
    expect(User.current).to be_nil
    expect(Thread.current[:origin_type]).to be_nil
  end

  it 'resets the context even when the job raises' do
    expect do
      middleware.call(nil, {}, 'default') do
        Entity.current = entity
        raise 'boom'
      end
    end.to raise_error('boom')

    expect(Entity.current).to be_nil
    expect(User.current).to be_nil
    expect(Thread.current[:origin_type]).to be_nil
  end

  it 'starts the job with a clean context even when the thread inherited one' do
    Entity.current = entity

    seen_inside = :unset
    middleware.call(nil, {}, 'default') { seen_inside = Entity.current }

    expect(seen_inside).to be_nil
  end

  it 'isolates two sequential jobs on the same thread' do
    middleware.call(nil, {}, 'default') { Entity.current = entity }

    second_job_context = :unset
    middleware.call(nil, {}, 'default') { second_job_context = Entity.current }

    expect(second_job_context).to be_nil
  end

  it 'returns the value yielded by the job' do
    expect(middleware.call(nil, {}, 'default') { :job_result }).to eq(:job_result)
  end

  describe 'server wiring (config/initializers/sidekiq_middleware.rb)' do
    it 'prepends the middleware to the server chain' do
      chain = Sidekiq::Middleware::Chain.new
      config = double('sidekiq config')
      allow(config).to receive(:server_middleware).and_yield(chain)
      allow(Sidekiq).to receive(:configure_server).and_yield(config)

      load Rails.root.join('config/initializers/sidekiq_middleware.rb')

      expect(chain.exists?(described_class)).to eq(true)
      expect(chain.entries.first.klass).to eq(described_class)
    end
  end
end
