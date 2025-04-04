require 'rails_helper'

RSpec.describe ComplementaryExamSettingsFetcher, type: :service do
  let(:classroom) {
    create(
      :classroom,
      :with_classroom_semester_steps
    )
  }
  let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom) }
  let(:discipline) { create(:discipline) }
  let(:step) { classroom.calendar.classroom_steps.first }
  let!(:complementary_exam_setting) {
    create(
      :complementary_exam_setting,
      :with_teacher_discipline_classroom,
      grade_ids: [classrooms_grade.grade_id]
    )
  }
  let(:complementary_exam) {
    create(
      :complementary_exam,
      :with_teacher_discipline_classroom,
      classroom: classroom,
      discipline: discipline,
      recorded_at: Date.current,
      step_id: step.id,
      complementary_exam_setting: complementary_exam_setting
    )
  }

  subject do
    described_class.new(classroom, discipline, step)
  end

  describe "#settings" do
    context "hasn't complementary_exams created" do
      it "return complementary exam settings" do
        expect(subject.settings.count).to eq(1)
      end
    end

    context "has complementary_exams created in same step" do
      before do
        complementary_exam
      end
      it "returns empty array" do
        expect(subject.settings.count).to eq(0)
      end
    end
  end
end
