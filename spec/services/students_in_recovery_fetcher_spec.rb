require 'rails_helper'

RSpec.describe StudentsInRecoveryFetcher, type: :service do
  let!(:classroom) {
    create(
      :classroom,
      :with_classroom_semester_steps
    )
  }
  let!(:exam_rule) {
    create(
      :exam_rule,
      recovery_type: RecoveryTypes::PARALLEL,
      parallel_recovery_average: 6
    )
  }
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
        expect(subject.fetch.pluck(:student)).to eq([student])
      end

      it 'does not return enrollment if student joined after the test' do
        student_enrollment_classroom.update(joined_at: '2017-03-02')
        expect(subject.fetch).to be_empty
      end

      it 'does not return enrollment if student left the same day as joined' do
        student_enrollment_classroom.update(left_at: '2017-01-02')
        expect(subject.fetch).to be_empty
      end

      it 'returns if student is in recovery' do
        avaliation = create(
          :avaliation,
          :with_teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline
        )
        
        daily_note = create(:daily_note, avaliation: avaliation)
        create(:daily_note_student, student: student, daily_note: daily_note, note: 2)
        expect(subject.fetch.pluck(:student)).to eq([student])
      end

      it 'does not return if student is not in recovery' do
        avaliation = create(
          :avaliation,
          :with_teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline
        )
        daily_note = create(:daily_note, avaliation: avaliation)
        create(:daily_note_student, student: student, daily_note: daily_note, note: 8)
        expect(subject.fetch).to be_empty
      end
    end

  end

end
