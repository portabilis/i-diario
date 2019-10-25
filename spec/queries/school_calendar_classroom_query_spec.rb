require 'rails_helper'

RSpec.describe SchoolCalendarClassroomQuery, type: :query do
  let(:unity) { create(:unity) }
  let!(:default_school_calendar) { create(:school_calendar, :with_one_step, year: 2016, unity: unity) }
  let(:classroom_one) { create(:classroom, year: 2016, unity: unity) }
  let(:classroom_two) { create(:classroom, year: 2017, unity: unity) }

  describe '#school_calendar' do
    it 'returns school_calendar when classroom year match to existing school_calendar' do
      school_calendar = SchoolCalendarClassroomQuery.new(classroom_one.unity, classroom_one).school_calendar

      expect(school_calendar).to be_a(SchoolCalendar)
    end
  end

  describe '#school_calendar' do
    it 'returns nil when classroom year doesnt match to existing school_calendar' do
      school_calendar = SchoolCalendarClassroomQuery.new(classroom_two.unity, classroom_two).school_calendar

      expect(school_calendar).to be(nil)
    end
  end
end
