require 'rails_helper'

RSpec.describe ComplementaryExamSettingsFetcher, type: :service do
  let(:unity) { create(:unity) }
  let(:classroom) { create(:classroom, :current, unity: unity) }
  let(:discipline) { create(:discipline) }
  let(:school_calendar) { create(:current_school_calendar_with_one_step, unity: unity) }
  let!(:complementary_exam_setting) { create(:complementary_exam_setting, grade_ids: [classroom.grade_id]) }
  let(:complementary_exam) {
    create(
      :complementary_exam,
      classroom: classroom,
      discipline: discipline,
      recorded_at: school_calendar.steps.first.school_day_dates[0],
      step_id: school_calendar.steps.first.id,
      complementary_exam_setting: complementary_exam_setting
    )
  }

  subject do
    described_class.new(classroom, discipline, school_calendar.steps.first)
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
