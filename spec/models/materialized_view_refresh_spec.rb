# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaterializedViewRefresh, type: :model do
  let(:entity) { Entity.find_by_domain('test.host') }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  describe '.register!' do
    let(:registered_at) { Time.zone.local(Date.current.year, 5, 10, 4, 30) }

    it 'creates the record on the first registration' do
      Timecop.freeze(registered_at) { described_class.register!('mvw_test') }

      expect(described_class.pluck(:view_name)).to eq(['mvw_test'])
      expect(described_class.first.refreshed_at).to eq(registered_at)
    end

    it 'updates the existing record on the following registrations' do
      create(:materialized_view_refresh, view_name: 'mvw_test', refreshed_at: 1.day.ago)

      Timecop.freeze(registered_at) { described_class.register!('mvw_test') }

      expect(described_class.where(view_name: 'mvw_test').count).to eq(1)
      expect(described_class.find_by(view_name: 'mvw_test').refreshed_at).to eq(registered_at)
    end
  end

  describe '.refreshed_at_for' do
    it 'returns the refresh timestamp of the view' do
      refreshed_at = Time.zone.local(Date.current.year, 5, 10, 4, 30)
      create(:materialized_view_refresh, view_name: 'mvw_test', refreshed_at: refreshed_at)

      expect(described_class.refreshed_at_for('mvw_test')).to eq(refreshed_at)
    end

    it 'returns nil when the view was never refreshed' do
      expect(described_class.refreshed_at_for('mvw_unknown')).to be_nil
    end
  end
end
