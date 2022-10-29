require 'rails_helper'

RSpec.describe LessonsBoardLesson, type: :model do
  subject {
    build(
      :lessons_board_lesson
    )
  }

  describe 'associations' do
    it { expect(subject).to belong_to(:lessons_board) }
  end
end
