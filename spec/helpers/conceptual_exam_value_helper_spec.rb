require 'rails_helper'

RSpec.describe ConceptualExamValueHelper, type: :helper do
  describe '#conceptual_exam_value_exempted?' do
    it 'returns true when exempted_discipline is the string "true"' do
      value = build_stubbed(:conceptual_exam_value, exempted_discipline: 'true')

      expect(helper.conceptual_exam_value_exempted?(value)).to eq(true)
    end

    it 'returns true when exempted_discipline is boolean true' do
      value = build_stubbed(:conceptual_exam_value, exempted_discipline: true)

      expect(helper.conceptual_exam_value_exempted?(value)).to eq(true)
    end

    it 'returns false when exempted_discipline is false' do
      value = build_stubbed(:conceptual_exam_value, exempted_discipline: false)

      expect(helper.conceptual_exam_value_exempted?(value)).to eq(false)
    end

    it 'returns false when exempted_discipline is nil' do
      value = build_stubbed(:conceptual_exam_value, exempted_discipline: nil)

      expect(helper.conceptual_exam_value_exempted?(value)).to eq(false)
    end
  end

  describe '#conceptual_exam_value_in_dependence?' do
    let(:dependence_discipline) { create(:discipline) }
    let(:regular_discipline) { create(:discipline) }

    before do
      allow(helper).to receive(:conceptual_exam_dependence_discipline_ids)
        .and_return(Set[dependence_discipline.id])
    end

    it 'returns true when the value discipline is in the dependence set' do
      value = build_stubbed(:conceptual_exam_value, discipline: dependence_discipline)

      expect(helper.conceptual_exam_value_in_dependence?(value)).to eq(true)
    end

    it 'returns false when the value discipline is not in the dependence set' do
      value = build_stubbed(:conceptual_exam_value, discipline: regular_discipline)

      expect(helper.conceptual_exam_value_in_dependence?(value)).to eq(false)
    end
  end
end
