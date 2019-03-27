require 'rails_helper'

RSpec.describe ExamPoster::FinalRecoveryPoster do
  let!(:unity) { create(:unity) }
  let!(:school_calendar) { create(:school_calendar_with_one_step, :current, unity: unity) }
  let!(:classroom) { create(:classroom_numeric, unity: unity) }
  let!(:recovery_diary_record) {
    create(
      :recovery_diary_record_with_students,
      classroom: classroom,
      recorded_at: school_calendar.steps.last.start_at + 1.day
    )
  }
  let!(:final_recovery_diary_record) {
    create(
      :final_recovery_diary_record,
      recovery_diary_record: recovery_diary_record,
      school_calendar: school_calendar
    )
  }
  let!(:teacher_discipline_classroom) {
    create(
      :teacher_discipline_classroom,
      classroom: classroom,
      discipline: recovery_diary_record.discipline
    )
  }
  let!(:user) { create(:user, assumed_teacher_id: teacher_discipline_classroom.teacher.id) }
  let!(:exam_posting) {
    create(
      :ieducar_api_exam_posting,
      school_calendar_step: school_calendar.steps.last,
      teacher: teacher_discipline_classroom.teacher,
      author: user
    )
  }

  subject { described_class.new(exam_posting, Entity.first.id, 'exam_posting_send') }

  it 'expects to call score_rounder with correct params' do
    score_rounder = double(:score_rounder)

    expect(ScoreRounder).to receive(:new)
      .with(classroom, RoundedAvaliations::FINAL_RECOVERY)
      .and_return(score_rounder)
      .at_least(:once)
    expect(score_rounder).to receive(:round)
      .with(anything)
      .at_least(:once)

    subject.post!
  end
end
