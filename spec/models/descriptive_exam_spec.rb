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

    context 'when the step belongs to the calendar of the classroom' do
      before { descriptive_exam.step_id = descriptive_exam.classroom.calendar.classroom_steps.first.id }

      it 'adds no error to the step' do
        descriptive_exam.valid?

        expect(descriptive_exam.errors[:step_id]).to be_empty
      end
    end

    context 'when the step belongs to the calendar of another classroom' do
      let(:other_classroom) { create(:classroom, :with_classroom_semester_steps) }

      before { descriptive_exam.step_id = other_classroom.calendar.classroom_steps.first.id }

      it 'adds an error to the step' do
        descriptive_exam.valid?

        expect(descriptive_exam.errors[:step_id]).to include('não pertence à turma selecionada')
      end
    end
  end
end
