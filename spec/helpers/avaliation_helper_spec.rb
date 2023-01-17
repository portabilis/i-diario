require 'rails_helper'

RSpec.describe AvaliationHelper, type: :helper do
  let(:teacher) { create(:teacher) }
  let(:test_setting) { TestSetting.find_by(year: 2017) }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps, :score_type_numeric_and_concept, teacher: teacher) }
  let(:avaliation) { create(:avaliation, :with_teacher_discipline_classroom, classroom: classroom, teacher: teacher) }

  describe '#avaliation_data' do
    context 'when params are correct and classroom is multi grade' do
      it 'returns grade ids' do
        expect(helper.avaliation_data(avaliation)).to eq(avaliation.grade_ids.join(','))
      end
    end

    context 'when grades are empty and classroom is multi grade' do
      it 'returns empty string' do
        allow(avaliation).to receive(:grade_ids).and_return([])
        expect(helper.avaliation_data(avaliation)).to eq('')
      end
    end

    context 'when params are correct and classroom is single grade' do
      it 'returns first grade id' do
        allow(classroom).to receive(:multi_grade?).and_return(false)
        allow(avaliation).to receive(:grade_ids).and_return([])
        expect(helper.avaliation_data(avaliation)).to eq(classroom.first_classroom_grade.grade.id)
      end
    end

  end
end
