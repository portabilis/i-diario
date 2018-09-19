require 'rails_helper'

RSpec.describe YearsFromUnityFetcher do
  let!(:unity) { create(:unity) }
  let!(:school_calendar_1) { create(:school_calendar, unity: unity, year: 2013) }
  let!(:school_calendar_2) { create(:school_calendar, unity: unity, year: 2014) }
  let!(:school_calendar_3) { create(:school_calendar, year: 2015) }

  subject do
    subject = described_class.new(unity.id)
  end

  it 'returns years of calendars of unity' do
    expect(subject.fetch).to match_array([2014, 2013])
  end

  it 'doesnt returns years of another unity' do
    expect(subject.fetch).to_not include(2015)
  end
end
