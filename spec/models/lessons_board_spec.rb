require 'rails_helper'

RSpec.describe LessonsBoard, type: :model do
  subject {
    build(
      :lessons_board
    )
  }

  describe 'associations' do
    it { expect(subject).to belong_to(:classrooms_grade) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:period) }
    it { expect(subject).to validate_presence_of(:classrooms_grade_id) }
  end
end
