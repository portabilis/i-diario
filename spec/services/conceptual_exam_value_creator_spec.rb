require 'rails_helper'

RSpec.describe ConceptualExamValueCreator, type: :service do
  let(:grade) { create_list(:grade, 2) }
  let(:teacher) { create_list(:teacher, 2) }
  let(:classroom) { create_list(:classroom, 2, :with_classroom_semester_steps) }
  let(:discipline) { create_list(:discipline, 2) }

  let(:classrooms_grade) {
    create(
      :classrooms_grade,
      :score_type_numeric_and_concept,
      classroom: classroom.first,
      grade: grade.first
    )
  }
  let(:student_enrollment_classroom) { create(:student_enrollment_classroom, classrooms_grade: classrooms_grade) }
  let(:conceptual_exam) {
    create(
      :conceptual_exam,
      :with_teacher_discipline_classroom,
      :with_one_value,
      discipline: discipline.first,
      teacher: teacher.first,
      grade: grade.first,
      classroom: classrooms_grade.classroom,
      student: student_enrollment_classroom.student_enrollment.student
    )
  }
  let(:teacher_discipline_classroom) {
    create(
      :teacher_discipline_classroom,
      classroom: classroom.first,
      grade: grade.first,
      teacher: teacher.first,
      discipline: discipline.last
    )
  }
  let(:school_calendar_discipline_grades) {
    create(
      :school_calendar_discipline_grade,
      grade: grade.first,
      discipline: discipline.first,
      school_calendar: classroom.first.unity.school_calendars.first
    )
    create(
      :school_calendar_discipline_grade,
      grade: grade.first,
      discipline: discipline.last,
      school_calendar: classroom.first.unity.school_calendars.first
    )
  }

  before do
    teacher_discipline_classroom
    conceptual_exam
    school_calendar_discipline_grades
  end

  context 'when the params are incorrect' do
    it 'should return ArgumentError' do
      expect {
        ConceptualExamValueCreator.create_empty_by(
          nil,
          nil,
          nil,
          nil
        )
      }.to raise_error(ArgumentError)
    end
  end

  context 'when ´teacher_discipline_classroom´ has no conceptual_exam' do
    subject(:new_conceptual_exam) {
      ConceptualExamValueCreator.create_empty_by(
        classroom.first,
        teacher.first,
        grade.first,
        discipline.last
      )
    }

    it 'should return list of new conceptual_exam with value nil' do
      expect(new_conceptual_exam.size).to eq(1)
      expect(new_conceptual_exam.first.discipline_id).to eq(teacher_discipline_classroom.discipline_id)
    end
  end

  context 'when ´teacher_discipline_classroom´ has conceptual_exam' do
    subject(:new_conceptual_exam) {
      ConceptualExamValueCreator.create_empty_by(
        classroom.first,
        teacher.first,
        grade.first,
        discipline.first
      )
    }

    it 'should not return conceptual exam list' do
      expect(new_conceptual_exam).to be_empty
    end
  end
end
