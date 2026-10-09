require 'rails_helper'

RSpec.describe RecoveryDiaryRecordStudent, type: :model do
  subject(:recovery_diary_record_student) { build(:recovery_diary_record_student) }

  describe 'attributes' do
    it { expect(subject).to respond_to(:score) }
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:recovery_diary_record) }
    it { expect(subject).to belong_to(:student) }
  end

  describe 'before_save: discard_score_change_for_inactive_student' do
    let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
    let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom) }
    let(:recorded_at) { Date.new(2017, 6, 1) }
    let(:recovery_diary_record) { RecoveryDiaryRecord.new(classroom_id: classroom.id, recorded_at: recorded_at) }

    def build_record(student, score)
      described_class.new(recovery_diary_record: recovery_diary_record, student_id: student.id, score: score)
    end

    def enroll(student)
      enrollment = create(:student_enrollment, student: student)
      create(
        :student_enrollment_classroom,
        classrooms_grade: classrooms_grade,
        student_enrollment: enrollment,
        joined_at: '2017-01-01',
        left_at: ''
      )
    end

    it 'keeps the score when the student is enrolled on the recorded date' do
      student = create(:student)
      enroll(student)
      record = build_record(student, 7)

      record.send(:discard_score_change_for_inactive_student)

      expect(record.score).to eq(7)
    end

    it 'reverts a new score when the student is not enrolled on the recorded date (blocks bypass)' do
      student = create(:student)
      record = build_record(student, 7)

      record.send(:discard_score_change_for_inactive_student)

      expect(record.score).to be_nil
    end

    it 'does not touch an unchanged score, even for a non-enrolled student (preserves existing data)' do
      student = create(:student)
      record = build_record(student, 7)
      allow(record).to receive(:score_changed?).and_return(false)

      record.send(:discard_score_change_for_inactive_student)

      expect(record.score).to eq(7)
    end
  end
end
