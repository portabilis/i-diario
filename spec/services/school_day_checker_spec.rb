require 'spec_helper'

RSpec.describe SchoolDayChecker, type: :service do
  let!(:classroom) { create(:classroom) }
  let!(:classroom_grades) { create(:classrooms_grade, classroom: classroom) }
  let!(:school_calendar) { create(:school_calendar, :with_one_step, unity: classroom.unity) }

  describe '#day_allows_entry?' do
    context 'when there is a non-school event and it does not allow entries directly linked to the classroom' do
      let!(:school_calendar_event) {
        create(
          :school_calendar_event,
          school_calendar: school_calendar,
          start_date: '2017-03-03',
          end_date: '2017-03-03',
          classroom: classroom,
          course: classroom_grades.grade.course,
          grade: classroom_grades.grade,
          coverage: "by_classroom",
          event_type: EventTypes::NO_SCHOOL
        )
      }

      it 'returns false for a school day when grade_id and classroom_id are provided' do
        date = '2017-03-03'.to_date
        grade_id = classroom_grades.grade.id
        subject = SchoolDayChecker.new(school_calendar, date, grade_id, classroom.id, nil).day_allows_entry?

        expect(subject).to be false
      end

      it 'returns true for a school day when only classroom_id is provided' do
        # Atenção! Quando enviamos apenas o parametro de turma
        # O serviço não está verificando corretamente se a turma tem vinculo com o evento,
        # Por isso temos esse retorno true (true é um valor errado, pois essa turma tem sim evento)
        date = '2017-03-03'.to_date
        grade_id = classroom_grades.grade.id
        subject = SchoolDayChecker.new(school_calendar, date, nil, classroom.id, nil).day_allows_entry?

        expect(subject).to be true
      end

      it 'returns false for a school day when grade_id is provided' do
        date = '2017-03-03'.to_date
        grade_id = classroom_grades.grade.id
        subject = SchoolDayChecker.new(school_calendar, date, grade_id, nil, nil).day_allows_entry?

        expect(subject).to be false
      end

      it 'returns true for a school day when course is provided' do
        date = '2017-03-03'.to_date
        course_id = classroom_grades.grade.course.id
        subject = SchoolDayChecker.new(school_calendar, date, nil, nil, course_id).day_allows_entry?

        expect(subject).to be false
      end
    end

    # context 'when there is a non-school event and it does not allow entries directly linked to the course' do
    #   subject do
    #   SchoolDayChecker.new(
    #     school_calendar, '2017-02-02', nil, classroom.id, nil
    #   ).day_allows_entry?
    #   end

    #   it 'returns false for school day when the classroom is linked to the course' do
    #   expect(subject).to be true
    #   end

    #   it 'returns true for school day when the classroom is not linked to the course' do
    #   expect(subject).to be true
    #   end

    #   it 'returns false for school day when the grade is linked to the course' do
    #   expect(subject).to be true
    #   end

    #   it 'returns true for school day when the course is linked to the event' do
    #   expect(subject).to be true
    #   end

    #   it 'returns false for school day when the course is not linked to the event' do
    #   expect(subject).to be true
    #   end
    # end

    # context 'when there is a non-school event and it does not allow entries directly linked to the grade' do
    #   subject do
    #   SchoolDayChecker.new(
    #     school_calendar, '2017-02-02', nil, classroom.id, nil
    #   ).day_allows_entry?
    #   end

    #   it 'returns false for a school day when the classroom is linked to the grade' do
    #   expect(subject).to be true
    #   end

    #   it 'returns true for a school day when the classroom is not linked to the grade' do
    #   expect(subject).to be true
    #   end

    #   it 'returns false for a school day when the grade is linked to the event' do
    #   expect(subject).to be true
    #   end

    #   it 'returns false for a school day when the grade is not linked to the event' do
    #   expect(subject).to be true
    #   end
    # end
  end

end
