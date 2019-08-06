require 'rails_helper'

RSpec.describe ExemptedDisciplinesInStep, type: :service do
  FIRST_STEP_NUMBER = 1
  SECOND_STEP_NUMBER = 2

  let!(:classroom) { create(:classroom) }
  let!(:discipline) { create(:discipline) }
  let!(:specific_step) do
    create(
      :specific_step,
      classroom: classroom,
      discipline: discipline,
      used_steps: FIRST_STEP_NUMBER
    )
  end

  describe '#discipline_ids' do
    context 'when discipline is exempted to classroom in step' do
      it 'returns discipline_id in array' do
        exempted_discipline_ids = subject.discipline_ids(classroom.id, SECOND_STEP_NUMBER)
        expect(exempted_discipline_ids).to include(discipline.id)
      end
    end

    context 'when discipline is not exempted to classroom in step' do
      it 'does not return discipline_id in array' do
        exempted_discipline_ids = subject.discipline_ids(classroom.id, FIRST_STEP_NUMBER)
        expect(exempted_discipline_ids).not_to include(discipline.id)
      end
    end

    context 'when discipline is required in both steps' do
      let!(:discipline) { create(:discipline) }
      let!(:specific_step) do
        create(
          :specific_step,
          classroom: classroom,
          discipline: discipline
        )
      end

      it 'does not return discipline_id in array to second step' do
        exempted_discipline_ids = subject.discipline_ids(classroom.id, SECOND_STEP_NUMBER)
        expect(exempted_discipline_ids).not_to include(discipline.id)
      end

      it 'does not return discipline_id in array to first step' do
        exempted_discipline_ids = subject.discipline_ids(classroom.id, FIRST_STEP_NUMBER)
        expect(exempted_discipline_ids).not_to include(discipline.id)
      end
    end
  end
end
