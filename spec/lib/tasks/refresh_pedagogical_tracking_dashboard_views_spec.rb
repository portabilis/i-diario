# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'refresh_pedagogical_tracking_views' do
  before do
    # Application nova a cada exemplo: o load acumula ações na mesma task.
    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load Rails.root.join('lib', 'tasks', 'refresh_pedagogical_tracking_dashboard_views.rake').to_s

    allow(Sidekiq).to receive(:redis)
  end

  it 'enqueues the chain with the active entities ordered by id' do
    active_entity = create(:entity, domain: 'active.test.host', disabled: false)
    disabled_entity = create(:entity, domain: 'disabled.test.host', disabled: true)

    enqueued_entity_ids = nil
    allow(RefreshPedagogicalTrackingViewsWorker).to receive(:enqueue_next) do |entity_ids|
      enqueued_entity_ids = entity_ids
    end

    Rake::Task['refresh_pedagogical_tracking_views'].invoke

    expect(enqueued_entity_ids).to include(active_entity.id)
    expect(enqueued_entity_ids).not_to include(disabled_entity.id)
    expect(enqueued_entity_ids).to eq(enqueued_entity_ids.sort)
  end

  it 'fails instead of enqueueing when redis is unavailable' do
    allow(Sidekiq).to receive(:redis).and_raise(Redis::CannotConnectError)

    expect(RefreshPedagogicalTrackingViewsWorker).not_to receive(:enqueue_next)

    expect {
      Rake::Task['refresh_pedagogical_tracking_views'].invoke
    }.to raise_error(Redis::CannotConnectError)
  end
end
