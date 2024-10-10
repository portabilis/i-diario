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
    allow(controller).to receive(:current_user_discipline).and_return(discipline)
    allow(controller).to receive(:current_teacher).and_return(current_teacher)
    allow(controller).to receive(:current_teacher_id).and_return(current_teacher.id)
    allow(controller).to receive(:recorded_at_by_step).and_return('2017-03-01')
    request.env['REQUEST_PATH'] = ''
  end

  describe "GET #new" do
    let!(:descriptive_exam) {
      create(
        :descriptive_exam,
        :with_teacher_discipline_classroom,
        discipline_id: discipline.id,
        classroom: classroom
      )
    }
    let!(:step) { descriptive_exam.step }

    before do
      get :new, params: { locale: 'pt-BR' }
    end

    context "when user is authorized" do
      it "assigns a new descriptive exam to @descriptive_exam" do
        expect(assigns(:descriptive_exam)).to be_a_new(DescriptiveExam)
      end

      it "sets @descriptive_exam classroom_id to current user's classroom" do
        expect(descriptive_exam.classroom_id).to eq(classroom.id)
      end

      it "sets @descriptive_exam discipline_id if opinion type is not 'Avaliação padrão (regular)'" do
        allow_any_instance_of(DescriptiveExam).to receive(:opinion_types).and_return([OpenStruct.new(text: "Avaliação inclusiva")])
        expect(descriptive_exam.discipline_id).to eq(discipline.id)
      end
    end

    context "when user is not authorized" do
      before {
        allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
        get :new, params: { locale: 'pt-BR' }
      }

      it "redirects to root path with an alert message" do
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        descriptive_exam: {
          classroom_id: classroom.id,
          discipline_id: discipline.id,
          recorded_at:  '2017-03-01',
          opinion_type: classrooms_grade.exam_rule.opinion_type,
          step_id: SchoolCalendarClassroomStep.first.id,
          students: [
            { id: student.id, student_id: student.id, dependence: false }
          ]
        },
        locale: 'pt-BR'
      }
    end

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

    context "with valid params" do
      it "creates a new descriptive exam" do
        expect {
          post :create, params: valid_params
        }.to change(DescriptiveExam, :count).by(1)
      end

      it "redirects to the edit path for the created exam" do
        post :create, params: valid_params
        expect(response).to redirect_to(edit_descriptive_exam_path(DescriptiveExam.last))
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          descriptive_exam: {
            classroom_id: 50,
            discipline_id: 50,
            recorded_at: Date.current,
            opinion_type: 'regular',
            students_attributes: []
          },
          locale: 'pt-BR'
        }
      end

      it "does not create a new exam and re-renders the new template" do
        expect {
          post :create, params: invalid_params
        }.to_not change(DescriptiveExam, :count)
        expect(flash[:error]).to match("Não localizamos uma regra de avaliação para a turma informada. Entre em contato com o administrador do sistema.")
      end
    end
  end

  describe "PUT #update" do
    let!(:descriptive_exam) {
      create(
        :descriptive_exam,
        :with_teacher_discipline_classroom,
        discipline_id: discipline.id,
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

    context "with valid params" do
      it "updates the requested descriptive exam" do
        put :update, params: { id: descriptive_exam.id, descriptive_exam: { recorded_at: Date.current }, locale: 'pt-BR' }
        descriptive_exam.reload
        expect(descriptive_exam.recorded_at).to eq(Date.current)
      end

      it "redirects to the new descriptive exam path" do
        put :update, params: { id: descriptive_exam.id, descriptive_exam: { recorded_at: Date.current }, locale: 'pt-BR' }
        expect(response).to redirect_to(new_descriptive_exam_path)
      end
    end

    context "with invalid params" do
      it "re-renders the edit template" do
        put :update, params: { id: descriptive_exam.id, descriptive_exam: { discipline_id: nil }, locale: 'pt-BR' }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "GET #find" do
    context "when valid params are provided" do

      it "returns the descriptive exam id as JSON" do
        descriptive_exam = create(
          :descriptive_exam,
          :with_teacher_discipline_classroom,
          discipline_id: discipline.id,
          classroom: classroom
        )
        get :find, params: { classroom_id: classroom.id, discipline_id: discipline.id, opinion_type: 'regular', locale: 'pt-BR' }
        expect(response.status).to eq(200)
      end
    end

    context "when invalid params are provided" do
      it "returns null as JSON" do
        get :find, params: { classroom_id: nil, opinion_type: 'regular', locale: 'pt-BR' }
        expect(response.body).to eq("null")
      end
    end
  end

end
