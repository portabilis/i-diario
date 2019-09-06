require 'rails_helper'

RSpec.describe LessonPlan, type: :model do
  subject {
    build(
      :lesson_plan,
      :with_teacher_discipline_classroom
    )
  }

  describe 'associations' do
    it { expect(subject).to belong_to(:school_calendar) }
    it { expect(subject).to belong_to(:classroom) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:school_calendar) }
    it { expect(subject).to validate_presence_of(:start_at) }
    it { expect(subject).to validate_presence_of(:end_at) }

    it 'should validate if there is at least one content assigned' do
      subject = build(
        :lesson_plan,
        :with_teacher_discipline_classroom,
        :without_contents
      )

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:contents]).to include('Conteúdos não pode ficar em branco')
    end
  end
end
