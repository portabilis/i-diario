require 'spec_helper'

RSpec.describe SchoolCalendarEventDays, type: :service do
  let!(:school_calendar) {
    create(
      :school_calendar,
      :with_trimester_steps
    )
  }
  let!(:school_calendar_event) {
    build(
      :school_calendar_event,
      school_calendar: school_calendar,
      coverage: 'by_grade',
      periods: Periods::MATUTINAL,
      event_type: EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY,
      grade_id: classroom_grades.grade_id,
      course_id: classroom_grades.classroom.course_id,
      show_in_frequency_record: false,
      start_date: '2017-02-10',
      end_date: '2017-02-16'
    )
  }
  let(:classroom) { create(:classroom, unity: school_calendar.unity) }
  let(:classroom_grades) {
    create(
      :classrooms_grade,
      classroom: classroom,
    )
  }
  let!(:daily_frequency) {
    create(
      :daily_frequency,
      classroom: classroom_grades.classroom,
      frequency_date: '2017-02-15',
      unity_id: classroom_grades.classroom.unity_id,
      school_calendar: school_calendar,
      period: Periods::MATUTINAL
    )
  }

  describe 'when to delete daily_frequencies' do
    context 'with coverage "by_grade" and event_type "extra_school_event_without_frequency"' do
      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendar],
          [school_calendar_event],
          'create',
          '2017-02-10',
          '2017-02-16'
        )
      end

      it 'delete only the daily_frequency in the by_grade' do
        expect{ subject }.to change{ DailyFrequency.count }.by(-1)
      end
    end


  end
end
