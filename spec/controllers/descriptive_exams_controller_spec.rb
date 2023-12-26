require 'spec_helper'

RSpec.describe DescriptiveExamsController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user, :with_user_role_administrator) }
  let(:user_role) { user.user_roles.first }
  let(:unity) { user_role.unity }
  let(:school_calendar) { create(:school_calendar, :with_one_step, unity: unity, opened_year: true) }
  let(:step) { school_calendar.steps.first }
  let(:current_teacher) { create(:teacher) }
  let(:exam_rule) { create(:exam_rule, opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE) }
  let(:classroom) {
    create(
      :classroom,
      :with_teacher_discipline_classroom,
      :with_classroom_semester_steps,
      unity: unity,
      school_calendar: school_calendar,
      teacher: current_teacher,
      discipline: discipline,
      exam_rule: exam_rule
    )
  }
  let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom, exam_rule: exam_rule) }
  let(:student_enrollment_classroom) { create(:student_enrollment_classroom, classrooms_grade: classrooms_grade) }
  let(:student_enrollment) { student_enrollment_classroom.student_enrollment }
  let(:student) { student_enrollment.student }
  let(:discipline) { create(:discipline) }

  let(:params) {
    {
      locale: 'pt-BR',
      descriptive_exam: {
        classroom_id: classroom.id,
        discipline_id: discipline.id,
        recorded_at:  '2017-03-01',
        opinion_type: classrooms_grade.exam_rule.opinion_type,
        step_id: step.id,
        students: [
          { id: student.id, student_id: student.id, dependence: false }
        ]
      }
    }
  }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  before do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:current_user_classroom).and_return(classroom)
    allow(controller).to receive(:current_teacher).and_return(current_teacher)
    allow(controller).to receive(:current_teacher_id).and_return(current_teacher.id)
    allow(controller).to receive(:recorded_at_by_step).and_return('2017-03-01')
    request.env['REQUEST_PATH'] = ''
  end

  describe 'POST #create' do
    context 'without success' do
      it 'fails to create and renders the new template' do
        post :create, params: params
        expect(response).to render_template(:new)
      end
    end

    context 'with success' do
      it 'creates and redirects to descriptive exams edit page' do
        allow(controller).to receive(:find_step_number).and_return(1)
        post :create, params: params
        expect(response).to redirect_to /avaliacoes-descritivas/
      end
    end
  end

  describe 'PUT #update' do
    let!(:descriptive_exam) {
      create(
        :descriptive_exam,
        :with_teacher_discipline_classroom,
        classroom: classroom
      )
    }
    let!(:step) { descriptive_exam.step }

    context 'when recorded at has no a valid date in step' do
      before do
        descriptive_exam.recorded_at = step.end_at + 1.day
      end

      it 'updates the descriptive exam' do
        expect(descriptive_exam.save).to be true
      end
    end
  end
end
