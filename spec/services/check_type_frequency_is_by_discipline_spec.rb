require 'rails_helper'

RSpec.describe CheckTypeFrequencyByDisciplineService, type: :service do
  let(:exam_rule) { create(:exam_rule) }
  let(:classroom) { create(:classroom, exam_rule: exam_rule) }
  let(:teacher_discipline_classroom) {
    create(
      :teacher_discipline_classroom,
      allow_absence_by_discipline: 0,
      classroom: classroom
    )
  }

  describe 'when the params are correct' do
    subject(:frequency_by_discipline) {
      CheckTypeFrequencyByDisciplineService.call(
        teacher_discipline_classroom.classroom_id, teacher_discipline_classroom.teacher
      )
    }

    context 'if frequencia do professor for por falta por disciplina' do
      before do
        teacher_discipline_classroom.update(allow_absence_by_discipline: 1)
      end

      # it 'is_expected to return true' do
      #   expect(frequency_by_discipline).to be_truthy
      # end
    end

    context 'if frequencia do professor for por falta por aula' do
      it 'is_expected to return false' do
        expect(frequency_by_discipline).to be_falsey
      end
    end
  end

  describe 'when the params are incorrect' do
    subject(:frequency_by_discipline) {
      CheckTypeFrequencyByDisciplineService.call(
        nil, teacher_discipline_classroom.teacher_id
      )
    }

    it 'Is expected returns nil if any parameter is nil or invalid' do
      expect{CheckTypeFrequencyByDisciplineService.call(
        nil, teacher_discipline_classroom.teacher_id
      )}.to nil
    end
  end
end
