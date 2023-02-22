require 'rails_helper'

RSpec.describe ConceptualExamValueCreator, type: :service do
  let(:unity) { create(:unity) }
  let(:classroom) { create(:classroom, unity: unity) }
  let(:discipline) { create(:discipline) }
  let(:teacher) { create(:teacher) }
  let(:grade) { create(:grade) }
  let(:teacher_discipline_classroom) {
    create(
      :teacher_discipline_classroom,
      classroom: classroom,
      discipline: discipline,
      teacher: teacher,
      grade: grade
    )
  }
  let(:current_user) { create(:user) }
  let(:school_calendar) { create(:school_calendar, :with_one_step, unity: classroom.unity)}
  let(:classrooms_grade) {
    create(
      :classrooms_grade,
      :score_type_numeric_and_concept,
      :with_classroom_semester_steps,
      classroom: classroom,
      grade: grade
    )
  }
  let(:student_enrollment_classroom) { create(:student_enrollment_classroom, classrooms_grade: classrooms_grade) }
  let(:conceptual_exam) {
    conceptual_exam = create(
      :conceptual_exam,
      :with_teacher_discipline_classroom,
      :with_one_value,
      classroom: classrooms_grade.classroom,
      student: student_enrollment_classroom.student_enrollment.student
    )
    current_user.current_classroom_id = conceptual_exam.classroom_id
    allow_any_instance_of(ConceptualExam).to receive(:current_user).and_return(current_user)

    conceptual_exam
  }
  let(:conceptual_exam_value) {
    create(
      :conceptual_exam_value,
      discipline: discipline,
      conceptual_exam: conceptual_exam
    )
  }

  before do
    school_calendar
    teacher_discipline_classroom
    conceptual_exam_value
    conceptual_exam
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

  context 'when you have a classroom and grades with new disciplines' do

    subject(:new_conceptual_exam) {
      ConceptualExamValueCreator.create_empty_by(
        classroom,
        discipline,
        teacher,
        grade
      )
    }

    it 'should return a new conceptual_exam with empty value' do
      binding.pry
      expect(new_conceptual_exam.size).to eq(1)
    end
  end
end
