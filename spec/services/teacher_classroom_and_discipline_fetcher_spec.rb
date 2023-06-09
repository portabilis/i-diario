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
        TeacherClassroomAndDisciplineFetcher.fetch!(teacher_discipline_classroom.teacher_id, unity, classroom.year)
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
      it 'should return empty hash if teacher teacher is invalid' do
        another_classroom = create(:classroom)

        expect(
          TeacherClassroomAndDisciplineFetcher.fetch!(1, another_classroom.unity, another_classroom.year)
        ).to eq(classrooms: [], disciplines: [], classroom_grades: [])
      end

      it 'should return empty hash if year is not equal to classroom' do
        another_classroom = create(:classroom, year: 2015)
        another_link = create(:teacher_discipline_classroom, year: 2015, classroom: classroom)

        expect(
          TeacherClassroomAndDisciplineFetcher.fetch!(another_link.teacher_id, another_classroom.unity, 2023)
        ).to eq(classrooms: [], disciplines: [], classroom_grades: [])
      end

      it 'should return nil if teacher and/or unity is blank' do
        another_classroom = create(:classroom, year: 2023)
        another_link = create(:teacher_discipline_classroom, year: 2023, classroom: another_classroom)

        expect(TeacherClassroomAndDisciplineFetcher.fetch!(nil, nil, 2023)).to be_nil
        expect(TeacherClassroomAndDisciplineFetcher.fetch!(nil, another_classroom.unity, 2023)).to be_nil
        expect(TeacherClassroomAndDisciplineFetcher.fetch!(another_link.teacher_id, nil, 2023)).to be_nil
      end

      it 'should return empty hash if unity has no link with teacher' do
        another_classroom = create(:classroom, id: 22, year: 2023)
        another_teacher = create(:teacher, id: 55)

        create(:teacher_discipline_classroom, id: 104, year: 2023)

        expect(
          TeacherClassroomAndDisciplineFetcher.fetch!(another_teacher.id, another_classroom.unity, another_classroom.year)
        ).to eq(classrooms: [], disciplines: [], classroom_grades: [])
      end
    end

    context 'when teacher has no connection with the discipline' do
      let(:another_classroom) { create(:classroom, id: 1577, year: 2023) }
      let(:another_teacher) { create(:teacher, id: 1755) }
      let(:another_discipline) { create(:discipline, id: 2566) }

      before do
        create(
          :teacher_discipline_classroom,
          id: 1245,
          classroom: another_classroom,
          teacher: another_teacher,
          year: 2023
        )
      end

      subject(:fetch_classrooms_disciplines_grades) {
        TeacherClassroomAndDisciplineFetcher.fetch!(another_teacher.id, another_classroom.unity, another_classroom.year)
      }

      it 'should return only hash with link of classroom' do
        expect(fetch_classrooms_disciplines_grades[:classrooms]).to contain_exactly(another_classroom)
      end

      it 'should not return disciplines without linked' do
        expect(fetch_classrooms_disciplines_grades[:disciplines]).not_to contain_exactly(another_discipline)
      end
    end
  end
end
