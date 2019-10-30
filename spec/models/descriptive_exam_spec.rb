# encoding: utf-8
require 'rails_helper'

RSpec.describe DescriptiveExam, type: :model do
  subject(:descriptive_exam) {
    build(
      :descriptive_exam,
      :with_teacher_discipline_classroom
    )
  }

  describe 'associations' do
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to have_many(:students).dependent(:destroy) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:classroom_id) }
    it { expect(subject).to validate_presence_of(:opinion_type) }
  end
end
