require 'rails_helper'

RSpec.describe ClassroomsGrade, type: :model do
  describe 'attributes' do
    it { expect(subject).to respond_to(:classroom_id) }
    it { expect(subject).to respond_to(:grade_id) }
    it { expect(subject).to respond_to(:exam_rule_id) }
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:grade) }
    it { expect(subject).to belong_to(:exam_rule) }
    it { expect(subject).to have_many(:student_enrollment_classrooms) }
    it { expect(subject).to have_one(:lessons_board) }
  end
end
