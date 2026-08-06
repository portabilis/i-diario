# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PedagogicalTrackingCalculator, type: :service do
  let(:entity) { Entity.find_by_domain('test.host') }
  let(:year) { Date.current.year }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  let(:unity) { create(:unity) }
  let!(:school_calendar) { create(:school_calendar, :with_one_step, unity: unity, year: year) }

  let(:params) do
    {
      search: {
        start_date: Date.new(year, 1, 1).to_s,
        end_date: Date.new(year, 12, 31).to_s
      }
    }
  end

  subject(:calculator) do
    described_class.new(
      entity: entity,
      year: year,
      current_user: nil,
      params: params,
      employee_unities: nil
    )
  end

  before do
    create(:unity_school_day, unity: unity, school_day: Date.new(year, 3, 10))
  end

  describe '#calculate_index_data' do
    describe 'updated_at' do
      it 'comes from the refresh record of the frequency view' do
        create(
          :materialized_view_refresh,
          view_name: MvwFrequencyBySchoolClassroomTeacher.table_name,
          refreshed_at: Time.zone.local(year, 5, 10, 4, 30)
        )

        data = calculator.calculate_index_data

        expect(data[:updated_at]).to eq(date: "10/05/#{year}", hour: 4)
      end

      it 'falls back to the refresh record of the content view' do
        create(
          :materialized_view_refresh,
          view_name: MvwContentRecordBySchoolClassroomTeacher.table_name,
          refreshed_at: Time.zone.local(year, 6, 20, 5, 15)
        )

        data = calculator.calculate_index_data

        expect(data[:updated_at]).to eq(date: "20/06/#{year}", hour: 5)
      end

      it 'is nil when no refresh was registered yet' do
        data = calculator.calculate_index_data

        expect(data[:updated_at]).to be_nil
      end
    end
  end
end
