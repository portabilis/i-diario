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

  it 'returns the value yielded by the job' do
    expect(middleware.call(nil, {}, 'default') { :job_result }).to eq(:job_result)
  end

  describe '.register' do
    it 'adds the middleware to the chain' do
      chain = Sidekiq::Middleware::Chain.new

      described_class.register(chain)

      expect(chain.exists?(described_class)).to eq(true)
    end
  end
end
