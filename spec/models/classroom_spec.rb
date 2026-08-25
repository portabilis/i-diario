require 'rails_helper'

RSpec.describe Classroom, type: :model do
  describe 'undiscard cascade' do
    let(:classroom) { create(:classroom) }
    let!(:classrooms_grade) { create(:classrooms_grade, classroom: classroom) }
    let!(:teacher_discipline_classroom) do
      create(:teacher_discipline_classroom, classroom: classroom)
    end

    before { classroom.discard }

    def undiscard_from_a_fresh_record
      Classroom.with_discarded.find(classroom.id).undiscard
    end

    it 'brings the teacher links back' do
      expect(
        TeacherDisciplineClassroom.with_discarded.find(teacher_discipline_classroom.id)
      ).to be_discarded

      undiscard_from_a_fresh_record

      expect(
        TeacherDisciplineClassroom.with_discarded.find(teacher_discipline_classroom.id)
      ).to be_kept
    end

    # A reativação dos vínculos de série pertence ao ClassroomsSynchronizer, que a restringe às
    # séries ainda devolvidas pela API. Um cascade aqui devolveria também as séries que saíram
    # da turma enquanto ela estava descartada.
    it 'leaves the grade links to the synchronizer' do
      undiscard_from_a_fresh_record

      expect(Classroom.with_discarded.find(classroom.id)).to be_kept
      expect(ClassroomsGrade.with_discarded.find(classrooms_grade.id)).to be_discarded
    end
  end
end
