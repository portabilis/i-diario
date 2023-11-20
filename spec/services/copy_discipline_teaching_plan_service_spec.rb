require 'rails_helper'

RSpec.describe CopyDisciplineTeachingPlanService, type: :service do
  let(:user) { create(:user, :with_user_role_administrator) }
  let(:discipline) { create(:discipline) }
  let(:classroom) { create(:classroom, :score_type_numeric) }
  let(:classroom_grades) { create(:classrooms_grade, classroom: classroom) }
  let(:current_teacher) { create(:teacher) }
  let(:school_term_type) { create(:school_term_type, description: 'Anual') }
  let(:school_term_type_step) { create(:school_term_type_step, school_term_type: school_term_type) }
  let(:teaching_plan) {
    create(
      :teaching_plan,
      :with_teacher_discipline_classroom,
      teacher: current_teacher,
      unity: classroom.unity,
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
      teaching_plan: teaching_plan,
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
end
