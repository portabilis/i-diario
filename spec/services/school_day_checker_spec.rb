require 'spec_helper'

RSpec.describe SchoolDayChecker, type: :service do
  let(:classroom) { create(:classroom) }
  let(:classroom_grades) { create_list(:classrooms_grade, 3, classroom: classroom)}
  let(:school_calendar) { create(:school_calendar, :with_one_step, unity: classroom.unity) }

  describe '#day_allows_entry?' do
    context 'when there is a non-school event and it does not allow entries directly linked to the classroom' do
      let!(:date) { '2017-03-03'.to_date }
      let!(:school_calendar_event) {
        create(
          :school_calendar_event,
          school_calendar: school_calendar,
          start_date: '2017-03-03',
          end_date: '2017-03-03',
          classroom: classroom,
          course: classroom_grades.first.grade.course,
          grade: classroom_grades.first.grade,
          coverage: "by_classroom",
          event_type: EventTypes::NO_SCHOOL
        )
      }

      it 'returns false for a school day when grade_id and classroom_id are provided' do
        grade_id = classroom_grades.first.grade.id
        subject = SchoolDayChecker.new(school_calendar, date, grade_id, classroom.id, nil).day_allows_entry?

        expect(subject).to be false
      end

      it 'returns true for a school day when only classroom_id is provided' do
        # Atenção! Quando enviamos apenas o parametro de turma
        # O serviço não está verificando corretamente se a turma tem vinculo com o evento,
        # Por isso temos esse retorno true (retorno correto seria false,
        #   pois essa turma tem vinculo com evento não letivo)
        grade_id = classroom_grades.first.grade.id
        subject = SchoolDayChecker.new(school_calendar, date, nil, classroom.id, nil).day_allows_entry?

        expect(subject).to be true
      end

      it 'returns false for a school day when grade_id is provided' do
        grade_id = classroom_grades.first.grade.id
        subject = SchoolDayChecker.new(school_calendar, date, grade_id, nil, nil).day_allows_entry?

        expect(subject).to be false
      end

      it 'returns true for a school day when course is provided' do
        course_id = classroom_grades.first.grade.course.id
        subject = SchoolDayChecker.new(school_calendar, date, nil, nil, course_id).day_allows_entry?

        expect(subject).to be false
      end
    end

    context 'when there is a non-school event and it does not allow entries directly linked to the course' do
      let(:date) { '2017-04-04'.to_date }
      let(:grade_id) { classroom_grades.first.grade.id }
      let!(:school_calendar_event) {
        create(
          :school_calendar_event,
          school_calendar: school_calendar,
          start_date: '2017-04-04',
          end_date: '2017-04-04',
          classroom: nil,
          course: classroom_grades.first.grade.course,
          grade: nil,
          coverage: "by_course",
          event_type: EventTypes::NO_SCHOOL
        )
      }

      it 'returns false for school day when only classroom_id is provided' do
        subject = SchoolDayChecker.new(school_calendar, date, nil, classroom.id, nil).day_allows_entry?
        expect(subject).to be false
      end

      it 'returns false for school day when the classroom_id and grade_id are provided' do
        subject = SchoolDayChecker.new(school_calendar, date, grade_id, classroom.id, nil).day_allows_entry?
        expect(subject).to be false
      end

      it 'returns false for school day when only grade is linked to the course' do
        subject = SchoolDayChecker.new(school_calendar, date, grade_id, nil, nil).day_allows_entry?
        expect(subject).to be false
      end

      it 'returns false for school day when only course is linked to the event' do
        course_id = classroom_grades.first.grade.course.id
        subject = SchoolDayChecker.new(school_calendar, date, nil, nil, course_id).day_allows_entry?
        expect(subject).to be false
      end
    end

    context 'when there is a non-school event and it does not allow entries directly linked to the grade' do
      let(:date) { '2017-05-05'.to_date }
      let(:grade_id) { classroom_grades.first.grade.id }
      let!(:school_calendar_event) {
        create(
          :school_calendar_event,
          school_calendar: school_calendar,
          start_date: '2017-05-05',
          end_date: '2017-05-05',
          classroom: nil,
          course: classroom_grades.first.grade.course,
          grade: classroom_grades.first.grade,
          coverage: "by_grade",
          event_type: EventTypes::NO_SCHOOL
        )
      }

      it 'returns true for a school day when only classroom is linked to the grade' do
        # Atenção! Quando enviamos apenas o parametro de turma
        # O serviço não está verificando corretamente se a turma tem vinculo com o evento,
        # Por isso temos esse retorno true (retorno correto seria false,
        #  pois essa turma tem vinculo com evento nao letivo)
        subject = SchoolDayChecker.new(school_calendar, date, nil, classroom.id, nil).day_allows_entry?
        expect(subject).to be true
      end

      it 'returns false for a school day when the classroom_id and grade_id are provided' do
        subject = SchoolDayChecker.new(school_calendar, date, grade_id, classroom.id, nil).day_allows_entry?
        expect(subject).to be false
      end

      it 'returns false for a school day when only grade is provided' do
        subject = SchoolDayChecker.new(school_calendar, date, grade_id, nil, nil).day_allows_entry?
        expect(subject).to be false
      end

      it 'returns false for a school day when the course is provided' do
        # Atenção! Quando enviamos apenas o parametro de curso
        # O serviço não está verificando corretamente se a curso tem vinculo com o evento,
        # Por isso temos esse retorno false (retorno correto seria true,
        #  pois esse evento não letivo está vinculado apenas para a serie e nao para o curso)
        course_id = classroom_grades.first.grade.course.id
        subject = SchoolDayChecker.new(school_calendar, date, nil, nil, course_id).day_allows_entry?

        expect(subject).to be false
      end
    end
  end

end
