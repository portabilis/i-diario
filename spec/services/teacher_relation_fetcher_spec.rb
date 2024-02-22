require 'rails_helper'

RSpec.describe TeacherRelationFetcher, type: :service do
  let(:unity) { create(:unity) }
  let(:classroom) { create(:classroom, unity: unity, year: '2023') }
  let(:discipline) { create(:discipline, knowledge_area: knowledge_areas.first) }
  let(:classroom_grades) { create_list(:classrooms_grade, 3, classroom: classroom) }
  let(:knowledge_areas) { [create(:knowledge_area)] }
  let(:teacher) { create(:teacher) }
  let!(:teacher_discipline_classroom) {
    create(
      :teacher_discipline_classroom,
      classroom: classroom,
      discipline: discipline,
      teacher: teacher
    )
  }

  subject do
    described_class.new({ teacher_id: teacher.id, discipline_id: discipline.id,
                          classroom: classroom,
                          grades: classroom_grades.map(&:id),
                          knowledge_areas: knowledge_areas.map(&:id) })
  end

  describe '#exists_classroom_in_relation?' do
    context 'when the teacher_discipline_classroom is releated to the classroom' do
      it 'returns true' do
        expect(subject.exists_classroom_in_relation?).to be_truthy
      end
    end

    context 'when the teacher_discipline_classroom is not releated to the classroom' do
      before { teacher_discipline_classroom.update(classroom: create(:classroom)) }

      it 'returns false' do
        expect(subject.exists_classroom_in_relation?).to be_falsey
      end
    end
  end

  describe '#exists_discipline_in_relation?' do
    context 'when the teacher_discipline_classroom is releated to the discipline' do
      it 'returns true' do
        expect(subject.exists_discipline_in_relation?).to be_truthy
      end
    end

    context 'when the teacher_discipline_classroom is not releated to the discipline' do
      before { teacher_discipline_classroom.update(discipline: create(:discipline)) }

      it 'returns false' do
        expect(subject.exists_discipline_in_relation?).to be_falsey
      end
    end
  end

  describe '#exists_all_knowledge_areas_in_relation?' do
    context 'when the teacher_discipline_classroom is releated to the knowledge_areas' do
      it 'returns true' do
        expect(subject.exists_all_knowledge_areas_in_relation?).to be_truthy
      end
    end

    context 'when the teacher_discipline_classroom is not releated to the knowledge_areas' do
      before { teacher_discipline_classroom.update(discipline: create(:discipline)) }

      it 'returns false' do
        expect(subject.exists_all_knowledge_areas_in_relation?).to be_falsey
      end
    end
  end

  describe '#exists_knowledge_area_in_relation?' do
    context 'when the teacher_discipline_classroom is releated to the knowledge_areas' do
      it 'returns true' do
        expect(subject.exists_knowledge_area_in_relation?).to be_truthy
      end
    end

    context 'when the teacher_discipline_classroom is not releated to the knowledge_areas' do
      before { teacher_discipline_classroom.update(discipline: create(:discipline)) }

      it 'returns false' do
        expect(subject.exists_knowledge_area_in_relation?).to be_falsey
      end
    end
  end

  describe '#exists_classroom_and_discipline_in_relation?' do
    context 'when the teacher_discipline_classroom is releated to the classroom and discipline' do
      it 'returns true' do
        expect(subject.exists_classroom_and_discipline_in_relation?).to be_truthy
      end
    end

    context 'when the teacher_discipline_classroom is not releated to the classroom' do
      before { teacher_discipline_classroom.update(classroom: create(:classroom)) }

      it 'returns false' do
        expect(subject.exists_classroom_and_discipline_in_relation?).to be_falsey
      end
    end

    context 'when the teacher_discipline_classroom is not releated to the discipline' do
      before { teacher_discipline_classroom.update(discipline: create(:discipline)) }

      it 'returns false' do
        expect(subject.exists_classroom_and_discipline_in_relation?).to be_falsey
      end
    end
  end
end
