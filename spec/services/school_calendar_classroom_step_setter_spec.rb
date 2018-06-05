require 'rails_helper'

RSpec.describe SchoolCalendarClassroomStepSetter, type: :service do
  let!(:classroom) { create(:classroom_numeric_and_concept) }
  let!(:school_calendar) { create(:current_school_calendar_with_one_step) }
  let!(:school_calendar_classroom) { create(:school_calendar_classroom, school_calendar: school_calendar, classroom: classroom) }
  let!(:school_calendar_classroom_step) { create(:school_calendar_classroom_step, school_calendar_classroom: school_calendar_classroom) }
  let(:conceptual_exam) { create(:conceptual_exam_with_one_value, school_calendar_step: school_calendar.steps.first, classroom: classroom) }
  let(:descriptive_exam) { create(:descriptive_exam, school_calendar_step: school_calendar.steps.first, classroom: classroom) }
  let(:transfer_note) { create(:transfer_note, school_calendar_step: school_calendar.steps.first, classroom: classroom) }
  let(:recovery_diary_record) { create(:current_recovery_diary_record_with_students, classroom: classroom) }
  let(:school_term_recovery_diary_record) { create(:current_school_term_recovery_diary_record,
                                                   school_calendar_step: school_calendar.steps.first,
                                                   recovery_diary_record: recovery_diary_record) }

  subject do
    SchoolCalendarClassroomStepSetter.new(school_calendar)
  end

  describe '#set_school_calendar_classroom_step' do
    context 'when there is no school_calendar_classroom_step_id' do
      it "in conceptual_exams" do
        conceptual_exam
        conceptual_exams = ConceptualExam.where(classroom_id: classroom_ids, school_calendar_classroom_step_id: nil)
        expect(conceptual_exams.count).to be(1)
        subject.set_school_calendar_classroom_step
        conceptual_exams = ConceptualExam.where(classroom_id: classroom_ids, school_calendar_classroom_step_id: nil)
        expect(conceptual_exams.count).to be(0)
      end

      it "in descriptive_exams" do
        descriptive_exam
        descriptive_exams = DescriptiveExam.where(classroom_id: classroom_ids, school_calendar_classroom_step_id: nil)
        expect(descriptive_exams.count).to be(1)
        subject.set_school_calendar_classroom_step
        descriptive_exams = DescriptiveExam.where(classroom_id: classroom_ids, school_calendar_classroom_step_id: nil)
        expect(descriptive_exams.count).to be(0)
      end

      it "in transfer_notes" do
        transfer_note
        transfer_notes = TransferNote.where(classroom_id: classroom_ids, school_calendar_classroom_step_id: nil)
        expect(transfer_notes.count).to be(1)
        subject.set_school_calendar_classroom_step
        transfer_notes = TransferNote.where(classroom_id: classroom_ids, school_calendar_classroom_step_id: nil)
        expect(transfer_notes.count).to be(0)
      end

      it "in school_term_recovery_diary_records" do
        school_term_recovery_diary_record
        school_term_recovery_diary_records = SchoolTermRecoveryDiaryRecord.by_classroom_id(classroom_ids).where(school_calendar_classroom_step_id: nil)
        expect(school_term_recovery_diary_records.count).to be(1)
        subject.set_school_calendar_classroom_step
        school_term_recovery_diary_records = SchoolTermRecoveryDiaryRecord.by_classroom_id(classroom_ids).where(school_calendar_classroom_step_id: nil)
        expect(school_term_recovery_diary_records.count).to be(0)
      end
    end
  end

  private

  def classroom_ids
    @classroom_ids ||= SchoolCalendarClassroom.joins(:school_calendar)
                                              .where(school_calendars: { unity_id: school_calendar['unity_id'].to_i })
                                              .map(&:classroom_id)
  end
end
