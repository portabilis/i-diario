require 'rails_helper'

RSpec.describe CopyDisciplineTeachingPlanService, type: :service do
  let(:user) { create(:user, :with_user_role_administrator) }
  let(:unity) { create(:unity) }
  let(:discipline) { create(:discipline) }
  let(:classroom) { create(:classroom, unity: unity) }
  let(:current_teacher) { create(:teacher) }
  let(:classroom_grades) { create(:classrooms_grade, classroom: classroom) }
  let(:school_term_type) { create(:school_term_type, description: 'Anual') }
  let(:school_term_type_step) { create(:school_term_type_step, school_term_type: school_term_type) }
  let(:teaching_plan) {
    create(
      :teaching_plan,
      :with_teacher_discipline_classroom,
      teacher: current_teacher,
      classroom: classroom,
      unity: unity,
      discipline: discipline,
      year: classroom.year,
      grade: classroom_grades.grade,
      school_term_type: school_term_type,
      school_term_type_step: school_term_type_step
    )
  }
  let(:discipline_teaching_plan) {
    create(
      :discipline_teaching_plan,
      discipline: discipline,
      teaching_plan: teaching_plan
    )
  }

  describe '#check_required_params' do
    context "when 'unities_ids' are blank" do
      it 'is expected an error reporting missing required parameters' do
        expect {
          CopyDisciplineTeachingPlanService.call(
            discipline_teaching_plan.id, classroom.year, [], [classroom_grades.grade_id]
          )
        }.to raise_error('Missing required parameters')
      end
    end

    context "when 'grade_ids' are blank" do
      it 'is expected an error reporting missing required parameters' do
        expect {
          CopyDisciplineTeachingPlanService.call(
            discipline_teaching_plan.id, classroom.year, [classroom.unity], []
          )
        }.to raise_error('Missing required parameters')
      end
    end

    context "when 'discipline_teaching_plan' are blank" do
      it 'is expected an error reporting missing required parameters' do
        expect {
          CopyDisciplineTeachingPlanService.call(
            nil, classroom.year, [classroom.unity], [classroom_grades.grade_id]
          )
        }.to raise_error('Missing required parameters')
      end
    end

    context "when 'year' are blank" do
      it 'is expected an error reporting missing required parameters' do
        expect {
          CopyDisciplineTeachingPlanService.call(
            discipline_teaching_plan.id, nil, [classroom.unity], [classroom_grades.grade_id]
          )
        }.to raise_error('Missing required parameters')
      end
    end
  end

  describe '#copy_discipline_teaching_plan_worker' do
    subject(:copy_discipline_teaching_plan) {
      CopyDisciplineTeachingPlanService.call(
        discipline_teaching_plan.id, classroom.year, [classroom.unity_id], [classroom_grades.grade_id]
      )
    }

    context 'when the registry copy is successful' do
      it 'is expected returns true' do
        expect(copy_discipline_teaching_plan).to be_truthy
      end

      it 'is expected returns an array with new discipline_teaching_plans' do
        expect(copy_discipline_teaching_plan).to be_an_instance_of(Array)
        expect(copy_discipline_teaching_plan.all? { |plan| plan.is_a?(DisciplineTeachingPlan) }).to be_truthy
      end
    end
  end

  describe 'when the copy is to be made for same grade' do
    context 'with 2 teachers in different classrooms at the same unity' do
      subject(:copy_discipline_teaching_plan) {
        CopyDisciplineTeachingPlanService.call(
          discipline_teaching_plan.id, classroom.year, [classroom.unity_id], [classroom_grades.grade_id]
        )
      }

      it 'is expected returns 2 copies' do
        other_teacher = create_setup_other_teacher_same_grade
        expect(copy_discipline_teaching_plan.count).to eq(2)
        expect(copy_discipline_teaching_plan.map(&:teaching_plan).map(&:teacher_id)).to eq(
          [other_teacher.id, current_teacher.id]
        )
      end
    end

    context 'with 1 teacher in different classrooms and unities' do
      let!(:other_unity) { create_setup_other_classroom_and_unity }

      subject(:copy_discipline_teaching_plan) {
        CopyDisciplineTeachingPlanService.call(
          discipline_teaching_plan.id, classroom.year, [classroom.unity_id, other_unity.id], [classroom_grades.grade_id]
        )
      }

      it 'is expected returns 2 copies' do
        expect(copy_discipline_teaching_plan.count).to eq(2)
        expect(copy_discipline_teaching_plan.map(&:teaching_plan).map(&:unity_id)).to eq(
          [classroom.unity_id, other_unity.id]
        )
      end
    end
  end

  describe 'when the copy is to be made for many grades' do
    context 'with 1 teacher in different classrooms' do
      let!(:other_grade) { create_setup_only_teacher_other_grade }

      subject(:copy_discipline_teaching_plan) {
        CopyDisciplineTeachingPlanService.call(
          discipline_teaching_plan.id,
          classroom.year,
          [classroom.unity_id],
          [classroom_grades.grade_id, other_grade.id]
        )
      }

      it 'is expected returns 2 copies' do
        expect(copy_discipline_teaching_plan.count).to eq(2)
        expect(copy_discipline_teaching_plan.map(&:teaching_plan).map(&:grade_id)).to eq(
          [other_grade.id, classroom_grades.grade_id]
        )
      end
    end
  end
end

# Cria vinculo para outro professor com outra turma mesma disciplina, mesma serie e ano
def create_setup_other_teacher_same_grade
  other_teacher = create(:teacher)
  other_classroom = create(:classroom, unity: unity)
  classroom_grades_with_grade = create(
    :classrooms_grade,
    classroom: other_classroom,
    grade: classroom_grades.grade
  )
  create(
    :teacher_discipline_classroom,
    teacher: other_teacher,
    classroom: other_classroom,
    discipline: discipline,
    grade: classroom_grades.grade
  )
  other_teacher
end

# Cria vinculo para o outro professor com outra turma e escola, mesma disciplina, mesma serie e ano
def create_setup_other_classroom_and_unity
  other_classroom = create(:classroom)
  other_classroom_grades = create(:classrooms_grade, classroom: other_classroom, grade: classroom_grades.grade)
  create(
    :teacher_discipline_classroom,
    teacher: current_teacher,
    classroom: other_classroom,
    discipline: discipline,
    grade: other_classroom_grades.grade
  )
  other_classroom.unity
end

# Cria vinculo para o mesmo professor com outra turma, mesma disciplina, outra série e ano
def create_setup_only_teacher_other_grade
  other_classroom = create(:classroom, unity: unity)
  other_classroom_grades = create(:classrooms_grade, classroom: other_classroom)
  create(
    :teacher_discipline_classroom,
    teacher: current_teacher,
    classroom: other_classroom,
    discipline: discipline,
    grade: other_classroom_grades.grade
  )
  other_classroom_grades.grade
end

# Para criar outro cenário - Criar vinculo para o professor turmas diferentes, mesma disciplina, escola e ano
# let(:classroom_2) { create(:classroom, unity: unity) }
# let(:classroom_grades_2) {
#   create(
#     :classrooms_grade,
#     classroom: classroom_2,
#     grade: classroom_grades.grade
#   )
# }
# let!(:teacher_discipline_classroom_2) {
#   create(
#     :teacher_discipline_classroom,
#     teacher: current_teacher,
#     classroom: classroom_2,
#     discipline: discipline,
#     grade: classroom_grades.grade
#   )
# }
