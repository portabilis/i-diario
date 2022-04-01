require 'rails_helper'

RSpec.describe KnowledgeArea, type: :model do
  describe 'associations' do
    it { expect(subject).to have_many(:disciplines) }
    it { expect(subject).to have_and_belong_to_many(:knowledge_area_content_records) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:description) }
    it { expect(subject).to validate_presence_of(:api_code) }
    it { expect(subject).to validate_uniqueness_of(:api_code) }
  end

  describe 'scopes' do
    let!(:teacher) { create(:teacher) }
    let!(:other_teacher) { create(:teacher) }
    let!(:classroom) { create(:classroom) }
    let!(:classrooms_grade) {
      create(:classrooms_grade, classroom: classroom)
    }
    let!(:other_classroom) { create(:classroom) }
    let!(:teacher_discipline_classroom_1) {
      create(:teacher_discipline_classroom, teacher: teacher, classroom: classroom)
    }
    let!(:teacher_discipline_classroom_2) {
      create(:teacher_discipline_classroom, teacher: teacher, classroom: classroom)
    }
    let!(:teacher_discipline_classroom_3) {
      create(:teacher_discipline_classroom, teacher: other_teacher, classroom: other_classroom)
    }

    describe '.by_unity' do
      it 'returns filtered Knowledge Areas by unity' do
        expect(described_class.by_unity(classroom.unity_id).count).to be(2)
      end
    end

    describe '.by_teacher' do
      it 'returns filtered Knowledge Areas by teacher' do
        expect(described_class.by_teacher(teacher.id).count).to be(2)
      end
    end

    describe '.by_classroom_id' do
      it 'returns filtered Knowledge Areas by classroom' do
        expect(described_class.by_classroom_id(classroom.id).count).to be(2)
      end
    end

    describe '.by_grade' do
      it 'returns filtered Knowledge Areas by grade' do
        expect(described_class.by_grade(classroom.first_grade.id).count).to be(2)
      end
    end
  end
end
