require 'rails_helper'

RSpec.describe AbsenceJustificationsStudent, type: :model do
  describe 'associations' do
    subject(:absence_justifications_student) { create(:absence_justifications_student) }

    it { expect(subject).to belong_to(:absence_justification) }
    it { expect(subject).to belong_to(:student) }
  end

  describe 'callbacks' do
    it 'should remove justification from student frequencies ' do
      absence_justifications_student = create(:absence_justifications_student, :with_daily_frequency)

      expect(DailyFrequencyStudent.first.absence_justification_student_id).to equal absence_justifications_student.id

      absence_justifications_student.absence_justification.destroy!

      expect(DailyFrequencyStudent.first.absence_justification_student_id).to be_nil
    end

    it 'should justify presence or absence already released' do
      daily_frequency = create(:daily_frequency, :with_teacher_discipline_classroom, :with_students)
      absence_justification = create(:absence_justification, teacher_discipline_classroom: TeacherDisciplineClassroom.first)
      daily_frequency_student = daily_frequency.students.first
      absence_justifications_student = create(
        :absence_justifications_student,
        student: daily_frequency_student.student,
        absence_justification: absence_justification,
      )

      daily_frequency_student.reload

      expect(daily_frequency_student.present).to equal false
      expect(daily_frequency_student.absence_justification_student_id).to equal absence_justifications_student.id
    end
  end
end
