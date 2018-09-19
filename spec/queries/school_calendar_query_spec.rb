require 'rails_helper'

RSpec.describe SchoolCalendarQuery, type: :query do
  let(:unity) { create(:unity) }
  let!(:school_calendar_from_2016) { create(:school_calendar_with_one_step, year: 2016, unity: unity) }
  let!(:school_calendar_from_current_year) { create(:school_calendar_with_one_step, year: Time.current.year, unity: unity) }

  describe '#school_calendar' do
    it 'return school_calendar from current year when year is not informed' do
      school_calendar = SchoolCalendarQuery.new(unity).school_calendar

      expect(school_calendar.year).to be(Time.current.year)
    end
  end

  describe '#school_calendar' do
    it 'return school_calendar matching to year passed by parameter' do
      year = 2016
      school_calendar = SchoolCalendarQuery.new(unity, year).school_calendar

      expect(school_calendar.year).to be(year)
    end
  end
end
