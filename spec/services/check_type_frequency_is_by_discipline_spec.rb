require 'rails_helper'

RSpec.describe CheckTypeFrequencyByDisciplineService, type: :service do
  let!(:school_calendar) { create(:school_calendar) }
  let(:exam_rule) { create(:exam_rule) }
  let(:classroom) { create(:classroom, exam_rule: exam_rule, unity: school_calendar.unity) }
  let!(:classroom_grades) { create(:classrooms_grade, classroom: classroom) }
  let!(:teacher_discipline_classroom) {
    create(
      :teacher_discipline_classroom,
      allow_absence_by_discipline: 0,
      classroom: classroom,
      grade: classroom_grades.grade
    )
  }

  describe 'when the params are correct' do
    subject(:frequency_by_discipline) {
      CheckTypeFrequencyByDisciplineService.call(
        teacher_discipline_classroom.classroom_id, teacher_discipline_classroom.teacher
      )
    }

    context 'and teacher has frequency is by absence by discipline' do
      before do
        teacher_discipline_classroom.update(allow_absence_by_discipline: 1)
      end

      it 'Is expected to return true' do
        expect(frequency_by_discipline).to be_truthy
      end
    end

    context 'and teacher has frequency is by absence by class' do
      it 'Is expected to return false' do
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
      expect(CheckTypeFrequencyByDisciplineService.call(
        nil, teacher_discipline_classroom.teacher_id
      )).to be_nil
    end
  end
end
