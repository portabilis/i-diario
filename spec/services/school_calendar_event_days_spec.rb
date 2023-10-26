require 'spec_helper'

RSpec.describe SchoolCalendarEventDays, type: :service do
  let!(:school_calendars) {
    create_list(
      :school_calendar,
      2,
      :with_trimester_steps
    )
  }
  let(:list_classrooms) { create_list(:classroom, 3, unity: school_calendars.first.unity) }
  let(:list_classroom_grades) {
    list_classrooms.map do |classroom|
      create(
        :classrooms_grade,
        classroom: classroom,
      )
    end
  }
  let!(:classroom_grades_with_grade) {
    create(
      :classrooms_grade,
      classroom: list_classrooms.second,
      grade: list_classroom_grades.last.grade
    )
  }

  describe 'when to delete daily_frequencies' do
    context 'with coverage "by_grade" and event_type "extra_school_event_without_frequency"' do
      let!(:school_calendar_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.first,
          coverage: 'by_grade',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY,
          grade_id: list_classroom_grades.first.grade_id,
          course_id: list_classroom_grades.first.grade.course_id,
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-10',
          end_date: '2017-02-16'
        )
      }
      let!(:daily_frequency) {
        create(
          :daily_frequency,
          classroom: list_classrooms.first,
          frequency_date: '2017-02-15',
          unity: list_classrooms.first.unity,
          school_calendar: school_calendars.first,
          period: Periods::MATUTINAL
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.first],
          [school_calendar_event],
          'create',
          '2017-02-10',
          '2017-02-16'
        )
      end

      it 'delete only the daily_frequency in the grade' do
        expect { subject }.to change { DailyFrequency.where(id: daily_frequency.id).count }.by(-1)
      end
    end

    context 'with coverage "by_unity" and event_type "extra_school_event_without_frequency"' do
      let(:list_classrooms_for_unity) { create_list(:classroom, 3, unity: school_calendars.last.unity) }
      let(:classroom_grades) {
        list_classrooms_for_unity.map do |classroom|
          create(
            :classrooms_grade,
            classroom: classroom,
          )
        end
      }
      let!(:school_calendar_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.last,
          coverage: 'by_unity',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY,
          grade_id: '',
          course_id: '',
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-10',
          end_date: '2017-02-16'
        )
      }

      let!(:daily_frequency) {
        create(
          :daily_frequency,
          id: 456,
          classroom: list_classrooms_for_unity.first,
          frequency_date: '2017-02-15',
          unity: school_calendars.last.unity,
          school_calendar: school_calendars.last,
          period: Periods::MATUTINAL
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.last],
          [school_calendar_event],
          'create',
          '2017-02-10',
          '2017-02-16'
        )
      end

      it 'delete only the daily_frequency in the unity' do
        expect { subject }.to change { DailyFrequency.where(id: daily_frequency.id).count }.by(-1)
      end
    end

    context 'with coverage "by_classroom" and event_type "extra_school_event_without_frequency"' do
      let!(:school_calendar_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.first,
          coverage: 'by_classroom',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY,
          grade_id: list_classroom_grades.last.grade_id,
          course_id: list_classroom_grades.last.grade.course_id,
          classroom_id: list_classrooms.second.id,
          show_in_frequency_record: false,
          start_date: '2017-02-10',
          end_date: '2017-02-16'
        )
      }
      let!(:daily_frequency) {
        create(
          :daily_frequency,
          classroom: list_classrooms.second,
          frequency_date: '2017-02-15',
          unity: list_classrooms.second.unity,
          school_calendar: school_calendars.first,
          period: Periods::MATUTINAL
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.first],
          [school_calendar_event],
          'create',
          '2017-02-10',
          '2017-02-16'
        )
      end

      it 'delete only the daily_frequency in the classroom' do
        expect { subject }.to change { DailyFrequency.where(id: daily_frequency.id).count }.by(-1)
      end
    end

    context 'with coverage "by_course" and event_type "extra_school_event_without_frequency"' do
      let!(:grade_with_course) {
        create(
          :grade,
          course: list_classroom_grades.last.grade.course
        )
      }
      let!(:school_calendar_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.first,
          coverage: 'by_course',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY,
          grade_id: '',
          course_id: grade_with_course.course_id,
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-10',
          end_date: '2017-02-16'
        )
      }
      let!(:daily_frequency) {
        create(
          :daily_frequency,
          classroom: list_classroom_grades.last.classroom,
          frequency_date: '2017-02-15',
          unity: list_classroom_grades.last.classroom.unity,
          school_calendar: school_calendars.first,
          period: Periods::MATUTINAL
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.first],
          [school_calendar_event],
          'create',
          '2017-02-10',
          '2017-02-16'
        )
      end

      it 'delete only the daily_frequency in the course' do
        expect { subject }.to change { DailyFrequency.where(id: daily_frequency.id).count }.by(-1)
      end
    end
  end
end
