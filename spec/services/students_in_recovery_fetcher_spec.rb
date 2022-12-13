require 'rails_helper'

RSpec.describe StudentsInRecoveryFetcher, type: :service do
  let!(:classroom) {
    create(
      :classroom,
      :with_classroom_semester_steps
    )
  }
  let!(:exam_rule) { create(:exam_rule, recovery_type: RecoveryTypes::PARALLEL) }
  let!(:classrooms_grade) {
    create(
      :classrooms_grade,
      classroom: classroom,
      exam_rule: exam_rule
    )
  }
  let!(:student_enrollment_classroom) {
    create(
      :student_enrollment_classroom,
      classrooms_grade: classrooms_grade,
      joined_at: '2017-01-02',
      left_at: ''
    )
  }
  let!(:student) { student_enrollment_classroom.student_enrollment.student }
  let!(:discipline) { create(:discipline) }
  let!(:step) { classroom.calendar.classroom_steps.first }
  let!(:ieducar_api_configuration) { create(:ieducar_api_configuration) }

  describe '#fetch' do
    subject do
      described_class.new(
        ieducar_api_configuration,
        classroom.id,
        discipline.id,
        step.id,
        '2017-03-01'
      )
    end

    context 'with only one enrollment' do
      it 'returns that enrollment if student is enrolled' do
        expect(subject.fetch).to eq([student])
      end

      it 'does not return that enrollment if student is not enrolled' do
        student_enrollment_classroom.update(joined_at: '2017-03-02')
        expect(subject.fetch).to be_empty
      end
    end

    context 'with a relocation within the same classroom' do
      it 'returns the classroom enrollment with higher api_code' do
        student_enrollment = create_student_enrollment
        create_student_enrollment_classroom(
          student_enrollment,
          joined_at: '2019-01-01',
          left_at: '2019-02-01'
        )
        create_relocation(student_enrollment, '2019-02-01', '')

        expect(subject.current_enrollment).to eq(@student_enrollment_classroom1)
      end
    end
  end

end
