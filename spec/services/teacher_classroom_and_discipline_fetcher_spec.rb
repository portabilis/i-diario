require 'rails_helper'

RSpec.describe TeacherClassroomAndDisciplineFetcher, type: :service do
  let(:unity) { create(:unity) }
  let(:classroom) { create(:classroom, unity: unity, year: '2023') }
  let(:discipline) { create(:discipline) }
  let(:classroom_grades) { create(:classrooms_grade, classroom: classroom) }
  let(:teacher_discipline_classroom) {
    create(
      :teacher_discipline_classroom,
      classroom: classroom,
      discipline: discipline
    )
  }

  before do
    classroom_grades
  end

  describe '#fetch!' do
    context 'when the required params are correct' do
      subject(:fetch_classrooms_disciplines_grades) {
        TeacherClassroomAndDisciplineFetcher.fetch!(
          teacher_discipline_classroom.teacher_id,
          unity,
          classroom.year
        )
      }

      it 'should return list of disciplines, classrooms and classroom_grades' do
        expect(fetch_classrooms_disciplines_grades.size).to eq(3)
      end

      it 'should ensure that params are valid' do
        expect(fetch_classrooms_disciplines_grades).to be_truthy
      end

      it 'should return list of disciplines' do
        expect(fetch_classrooms_disciplines_grades[:disciplines]).to contain_exactly(discipline)
      end

      it 'should return list of classrooms' do
        expect(fetch_classrooms_disciplines_grades[:classrooms]).to contain_exactly(classroom)
      end

      it 'should return hash of classroom_grades' do
        expect(fetch_classrooms_disciplines_grades[:classroom_grades]).to contain_exactly(classroom_grades)
      end
    end
    context 'when the required params are incorrect' do
      it 'should return Error:Wrong number of arguments' do
        expect { TeacherClassroomAndDisciplineFetcher.fetch!(unity, classroom.year) }.to
        raise_error(ArgumentError, 'wrong number of arguments (given 2, expected 3)')

        expect { TeacherClassroomAndDisciplineFetcher.fetch! }.to
        raise_error(ArgumentError, 'wrong number of arguments (given 0, expected 3)')
      end

      it 'should return empty hashs' do
        another_classroom = create(:classroom)

        expect(
          TeacherClassroomAndDisciplineFetcher.fetch!(1, another_classroom.unity, another_classroom.year)
        ).to eq(classrooms: [], disciplines: [], classroom_grades: [])
      end
    end
  end
end
