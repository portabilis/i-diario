require 'rails_helper'

RSpec.describe LessonsBoardLessonWeekday, type: :model do
  subject {
    build(
      :lessons_board_lesson_weekday
    )
  }

  describe 'associations' do
    it { expect(subject).to belong_to(:teacher_discipline_classroom) }
    it { expect(subject).to belong_to(:lessons_board_lesson) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:teacher_discipline_classroom_id) }
    it { expect(subject).to validate_presence_of(:lessons_board_lesson_id) }
  end
end
