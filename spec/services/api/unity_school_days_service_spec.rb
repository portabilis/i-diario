require 'rails_helper'

RSpec.describe Api::UnitySchoolDaysService do
  let(:unity) { create(:unity, api_code: 'unity-1') }
  let(:other_unity) { create(:unity, api_code: 'unity-2') }
  let(:start_at) { Date.new(2026, 6, 1) }
  let(:end_at) { Date.new(2026, 6, 30) }
  let(:unities) { [unity] }

  subject(:result) { described_class.call(unities: unities, start_at: start_at, end_at: end_at) }

  it 'lists the school days of the unity in ascending order' do
    create(:unity_school_day, unity: unity, school_day: '2026-06-03')
    create(:unity_school_day, unity: unity, school_day: '2026-06-01')
    create(:unity_school_day, unity: unity, school_day: '2026-06-02')

    expect(result).to eq(
      [
        {
          unity_api_code: 'unity-1',
          school_days: %w[2026-06-01 2026-06-02 2026-06-03]
        }
      ]
    )
  end

  it 'ignores days outside the period and of other unities' do
    create(:unity_school_day, unity: unity, school_day: '2026-06-10')
    create(:unity_school_day, unity: unity, school_day: '2026-05-20')
    create(:unity_school_day, unity: other_unity, school_day: '2026-06-10')

    expect(result).to eq([{ unity_api_code: 'unity-1', school_days: ['2026-06-10'] }])
  end

  context 'with more than one unity' do
    let(:unities) { [unity, other_unity] }

    it 'returns one entry per unity, with its own days' do
      create(:unity_school_day, unity: unity, school_day: '2026-06-01')
      create(:unity_school_day, unity: unity, school_day: '2026-06-02')
      create(:unity_school_day, unity: other_unity, school_day: '2026-06-03')

      expect(result).to match_array(
        [
          { unity_api_code: 'unity-1', school_days: %w[2026-06-01 2026-06-02] },
          { unity_api_code: 'unity-2', school_days: %w[2026-06-03] }
        ]
      )
    end
  end
end
