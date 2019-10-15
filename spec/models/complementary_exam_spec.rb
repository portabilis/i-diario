require 'rails_helper'

RSpec.describe ComplementaryExam, type: :model do
  subject do
    create(:complementary_exam, :with_teacher_discipline_classroom)
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to belong_to(:complementary_exam_setting) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:unity) }
    it { expect(subject).to validate_presence_of(:discipline) }
    it { expect(subject).to validate_presence_of(:complementary_exam_setting) }

    it 'should validate the year of recorded_at is the same as the year of the settings of the exam' do
      expect(subject.complementary_exam_setting.year).to eq(subject.recorded_at.year)
    end
  end
end
