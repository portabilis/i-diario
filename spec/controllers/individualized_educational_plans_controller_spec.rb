require 'rails_helper'

RSpec.describe IndividualizedEducationalPlansController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user, :with_user_role_administrator) }

  around(:each) do |example|
    entity.using_connection { example.run }
  end

  before do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:require_current_teacher).and_return(true)
  end

  describe 'GET #index' do
    context 'as an admin/employee' do
      let(:classroom) { create(:classroom) }

      before { allow(controller).to receive(:current_user_classroom).and_return(classroom) }

      it 'lists only plans of the selected classroom' do
        target = create(:individualized_educational_plan, classroom: classroom)
        create(:individualized_educational_plan) # plano em outra turma, deve ser excluído

        get :index, params: { locale: 'pt-BR' }

        expect(response).to have_http_status(:ok)
        expect(assigns(:individualized_educational_plans)).to contain_exactly(target)
      end

      it 'filters by student' do
        target = create(:individualized_educational_plan, classroom: classroom)
        create(:individualized_educational_plan, classroom: classroom)

        get :index, params: { locale: 'pt-BR', filter: { by_student_id: target.student_id } }

        expect(assigns(:individualized_educational_plans)).to contain_exactly(target)
      end

      it 'paginates the plans (default 10 per page)' do
        create_list(:individualized_educational_plan, 11, classroom: classroom)

        get :index, params: { locale: 'pt-BR', page: 2 }

        expect(assigns(:individualized_educational_plans).to_a.size).to eq(1)
      end
    end

    context 'without a classroom selected in the profile' do
      before { allow(controller).to receive(:current_user_classroom).and_return(nil) }

      it 'redirects to the root path' do
        get :index, params: { locale: 'pt-BR' }

        expect(response).to redirect_to(root_path)
      end
    end

    context 'as a teacher' do
      let(:teacher) { create(:teacher) }
      let(:selected_unity) { create(:unity) }
      let(:classroom) { create(:classroom, unity: selected_unity, year: Date.current.year) }

      before do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:current_role_is_admin_or_employee?).and_return(false)
        allow(controller).to receive(:current_teacher).and_return(teacher)
        allow(controller).to receive(:current_unity).and_return(selected_unity)
        allow(controller).to receive(:current_school_year).and_return(Date.current.year)
        allow(controller).to receive(:current_user_classroom).and_return(classroom)
        create(:teacher_discipline_classroom, teacher: teacher, classroom: classroom, year: Date.current.year)
      end

      it 'opens filtered by the profile classroom' do
        other_classroom = create(:classroom, unity: selected_unity, year: Date.current.year)
        create(:teacher_discipline_classroom, teacher: teacher, classroom: other_classroom, year: Date.current.year)
        target = create(:individualized_educational_plan, classroom: classroom, year: Date.current.year)
        create(:individualized_educational_plan, classroom: other_classroom, year: Date.current.year)

        get :index, params: { locale: 'pt-BR' }

        expect(response).to have_http_status(:ok)
        expect(assigns(:individualized_educational_plans)).to contain_exactly(target)
      end

      it 'lists all teacher classrooms when the classroom filter is cleared' do
        other_classroom = create(:classroom, unity: selected_unity, year: Date.current.year)
        create(:teacher_discipline_classroom, teacher: teacher, classroom: other_classroom, year: Date.current.year)
        plan_in_profile = create(:individualized_educational_plan, classroom: classroom, year: Date.current.year)
        plan_in_other = create(:individualized_educational_plan, classroom: other_classroom, year: Date.current.year)

        get :index, params: { locale: 'pt-BR', filter: { by_classroom_id: '' } }

        expect(assigns(:individualized_educational_plans)).to contain_exactly(plan_in_profile, plan_in_other)
      end

      it 'renders empty when the teacher has no linked classrooms' do
        allow(TeacherClassroomAndDisciplineFetcher).to receive(:fetch!).and_return(nil)
        create(:individualized_educational_plan, classroom: classroom)

        get :index, params: { locale: 'pt-BR' }

        expect(response).to have_http_status(:ok)
        expect(assigns(:individualized_educational_plans)).to be_empty
      end
    end
  end

  describe 'DELETE #destroy' do
    before { allow(controller).to receive(:current_user_classroom).and_return(create(:classroom)) }

    it 'destroys the plan and redirects to the index' do
      plan = create(:individualized_educational_plan)

      expect {
        delete :destroy, params: { locale: 'pt-BR', id: plan.id }
      }.to change(IndividualizedEducationalPlan, :count).by(-1)

      expect(response).to redirect_to(individualized_educational_plans_path)
    end
  end

  describe 'GET #fetch_students_by_classroom' do
    before { allow(controller).to receive(:current_user_classroom).and_return(create(:classroom)) }

    let(:classroom) { create(:classroom) }

    it 'returns only students that have a plan in the classroom' do
      plan = create(:individualized_educational_plan, classroom: classroom)
      create(:individualized_educational_plan)

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: classroom.id, format: :json }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to contain_exactly('id' => plan.student_id, 'name' => plan.student.name)
    end
  end

  describe 'GET #student_data' do
    before do
      allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))
      allow(controller).to receive(:current_school_year).and_return(Date.current.year)
    end

    it 'returns the student identification data with the existing-plan flag' do
      student = create(:student)
      allow(IndividualizedEducationalPlanPrefill).to receive(:student_data)
        .and_return(birth_date: '10/03/2015', diagnosis: 'TEA', guardians: 'Maria Silva')

      get :student_data, params: { locale: 'pt-BR', student_id: student.id, format: :json }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        'birth_date' => '10/03/2015', 'diagnosis' => 'TEA', 'guardians' => 'Maria Silva',
        'has_existing_plan' => false
      )
    end

    it 'flags when the student already has a plan for the year' do
      allow(IndividualizedEducationalPlanPrefill).to receive(:student_data).and_return({})
      plan = create(:individualized_educational_plan, year: Date.current.year)

      get :student_data, params: { locale: 'pt-BR', student_id: plan.student_id, format: :json }

      expect(JSON.parse(response.body)['has_existing_plan']).to eq(true)
    end

    it 'ignores the plan being edited when flagging (plan_id)' do
      allow(IndividualizedEducationalPlanPrefill).to receive(:student_data).and_return({})
      plan = create(:individualized_educational_plan, year: Date.current.year)

      get :student_data, params: {
        locale: 'pt-BR', student_id: plan.student_id, plan_id: plan.id, format: :json
      }

      expect(JSON.parse(response.body)['has_existing_plan']).to eq(false)
    end
  end

  describe 're-rendering the form after a failure' do
    before do
      allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))
      allow(IeducarApiConfiguration).to receive(:current).and_return(double(to_api: {}))
      allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {}))
    end

    it 'repopulates the display fields on a create validation failure' do
      unity = create(:unity)
      classroom = create(:classroom, unity: unity)
      teacher = create(:teacher)
      student = create(:student)
      create(:individualized_educational_plan, student: student, year: Date.current.year) # dispara duplicidade

      post :create, params: {
        locale: 'pt-BR',
        individualized_educational_plan: {
          student_id: student.id, unity_id: unity.id, classroom_id: classroom.id,
          teacher_id: teacher.id, year: Date.current.year, elaborated_at: Date.current
        }
      }

      expect(response).to render_template(:new)
      plan = assigns(:individualized_educational_plan)
      expect(plan.unity_name).to eq(unity.name)
      expect(plan.classroom_name).to eq(classroom.description)
      expect(plan.teacher_name).to eq(teacher.name)
    end
  end

  describe 'GET #new' do
    it 'assigns the classroom regent (i-Educar) as the teacher' do
      regent = create(:teacher, api_code: '777')
      classroom = create(:classroom, regent_api_code: '777')
      allow(controller).to receive(:current_user_classroom).and_return(classroom)

      get :new, params: { locale: 'pt-BR' }

      expect(assigns(:individualized_educational_plan).teacher_id).to eq(regent.id)
    end

    it 'leaves the teacher blank when the classroom has no regent (no fallback)' do
      classroom = create(:classroom, regent_api_code: nil)
      allow(controller).to receive(:current_user_classroom).and_return(classroom)
      allow(controller).to receive(:current_teacher).and_return(create(:teacher))

      get :new, params: { locale: 'pt-BR' }

      expect(assigns(:individualized_educational_plan).teacher_id).to be_nil
    end

    it 'shows 3 review date fields by default' do
      allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))

      get :new, params: { locale: 'pt-BR' }

      expect(assigns(:individualized_educational_plan).iep_review_dates.size).to eq(3)
    end
  end

  describe 'GET #edit' do
    before do
      allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))
      allow(IeducarApiConfiguration).to receive(:current).and_return(double(to_api: {}))
      allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {}))
    end

    it 'keeps 3 review date fields, completing the persisted ones' do
      plan = create(:individualized_educational_plan)
      create(:iep_review_date, iep: plan, review_date: Date.current)

      get :edit, params: { locale: 'pt-BR', id: plan.id }

      review_dates = assigns(:individualized_educational_plan).iep_review_dates
      expect(review_dates.size).to eq(3)
      expect(review_dates.select(&:persisted?).map(&:review_date)).to eq([Date.current])
    end
  end

  describe 'POST #create' do
    before { allow(controller).to receive(:current_user_classroom).and_return(create(:classroom)) }

    let(:valid_params) do
      {
        student_id: create(:student).id,
        unity_id: create(:unity).id,
        classroom_id: create(:classroom).id,
        teacher_id: create(:teacher).id,
        year: Date.current.year,
        elaborated_at: Date.current,
        characterization: 'Perfil do estudante',
        iep_review_dates_attributes: { '0' => { review_date: Date.current + 30 } }
      }
    end

    it 'creates a draft plan and redirects to the index' do
      expect do
        post :create, params: { locale: 'pt-BR', individualized_educational_plan: valid_params }
      end.to change(IndividualizedEducationalPlan, :count).by(1)

      expect(response).to redirect_to(individualized_educational_plans_path)
    end

    it 'persists the review dates' do
      post :create, params: { locale: 'pt-BR', individualized_educational_plan: valid_params }

      expect(IndividualizedEducationalPlan.last.iep_review_dates.map(&:review_date)).to eq([Date.current + 30])
    end

    it 'assigns the multi-select options' do
      option = create(:iep_option)

      post :create, params: {
        locale: 'pt-BR',
        individualized_educational_plan: valid_params.merge(communication_profile_option_ids: [option.id])
      }

      expect(IndividualizedEducationalPlan.last.communication_profile_option_ids).to eq([option.id])
    end

    it 'assigns the multi-select options submitted as a comma-separated string (select2 format)' do
      options = create_list(:iep_option, 2)

      post :create, params: {
        locale: 'pt-BR',
        individualized_educational_plan: valid_params.merge(
          communication_profile_option_ids: options.map(&:id).join(',')
        )
      }

      expect(IndividualizedEducationalPlan.last.communication_profile_option_ids).to match_array(options.map(&:id))
    end

    it 'does not create an invalid plan (missing required fields)' do
      expect do
        post :create, params: {
          locale: 'pt-BR', individualized_educational_plan: valid_params.merge(student_id: nil)
        }
      end.not_to change(IndividualizedEducationalPlan, :count)
    end

    # As linhas das seções 4/5 pertencem a uma revisão prevista já salva,
    # por isso são persistidas via update (fluxo real: salvar a seção 1 antes).
    it 'persists section 4 (curricular planning) and section 5 (periodic evaluation) linked to a review' do
      plan = create(:individualized_educational_plan)
      review_date = create(:iep_review_date, iep: plan)
      discipline = create(:discipline)
      accommodation = create(:iep_option, :instructional_accommodation)

      patch :update, params: {
        locale: 'pt-BR', id: plan.id,
        individualized_educational_plan: {
          iep_curricular_plannings_attributes: { '0' => {
            iep_review_date_id: review_date.id, discipline_id: discipline.id,
            long_term_goal: 'Meta anual',
            instructional_accommodation_option_ids: [accommodation.id]
          } },
          iep_periodic_evaluations_attributes: { '0' => {
            iep_review_date_id: review_date.id, discipline_id: discipline.id,
            acquired_skills: 'Habilidades adquiridas'
          } }
        }
      }

      planning = plan.reload.iep_curricular_plannings.first
      expect(planning.long_term_goal).to eq('Meta anual')
      expect(planning.iep_review_date_id).to eq(review_date.id)
      expect(planning.instructional_accommodation_option_ids).to eq([accommodation.id])
      expect(plan.iep_periodic_evaluations.first.acquired_skills).to eq('Habilidades adquiridas')
    end

    it 'does not persist pre-rendered section 4/5 forms without content' do
      plan = create(:individualized_educational_plan)
      review_date = create(:iep_review_date, iep: plan)
      discipline = create(:discipline)

      patch :update, params: {
        locale: 'pt-BR', id: plan.id,
        individualized_educational_plan: {
          iep_curricular_plannings_attributes: { '0' => {
            iep_review_date_id: review_date.id, discipline_id: discipline.id,
            long_term_goal: '', stage_objectives: '', skills_to_develop: '', methodologies: '',
            instructional_accommodation_option_ids: '', environmental_accommodation_option_ids: '',
            assessment_accommodation_option_ids: ''
          } },
          iep_periodic_evaluations_attributes: { '0' => {
            iep_review_date_id: review_date.id, discipline_id: discipline.id,
            acquired_skills: '', in_progress_skills: '', not_acquired_skills: '',
            period_report: '', next_stage_adjustments: ''
          } }
        }
      }

      expect(plan.reload.iep_curricular_plannings).to be_empty
      expect(plan.iep_periodic_evaluations).to be_empty
    end
  end

  describe 'PATCH #update' do
    before { allow(controller).to receive(:current_user_classroom).and_return(create(:classroom)) }

    it 'renders edit with a friendly error when removing a review that has section data' do
      plan = create(:individualized_educational_plan)
      review_date = create(:iep_review_date, iep: plan)
      create(:iep_curricular_planning, iep: plan, iep_review_date: review_date, long_term_goal: 'Meta')

      patch :update, params: {
        locale: 'pt-BR', id: plan.id,
        individualized_educational_plan: {
          iep_review_dates_attributes: { '0' => { id: review_date.id, _destroy: '1' } }
        }
      }

      expect(response).to render_template(:edit)
      expect(assigns(:individualized_educational_plan).errors[:base])
        .to include(I18n.t('activerecord.errors.models.iep_review_date.in_use'))
      expect(IepReviewDate.exists?(review_date.id)).to eq(true)

      blocked = assigns(:individualized_educational_plan).iep_review_dates.detect { |review| review.id == review_date.id }
      expect(blocked.errors[:review_date]).to include(
        I18n.t('activerecord.errors.models.iep_review_date.attributes.review_date.cannot_remove')
      )
    end

    it 'highlights every removed review that has section data (not only the first)' do
      plan = create(:individualized_educational_plan)
      first_review = create(:iep_review_date, iep: plan)
      second_review = create(:iep_review_date, iep: plan)
      create(:iep_curricular_planning, iep: plan, iep_review_date: first_review, long_term_goal: 'Meta')
      create(:iep_periodic_evaluation, iep: plan, iep_review_date: second_review, acquired_skills: 'Habilidades')

      patch :update, params: {
        locale: 'pt-BR', id: plan.id,
        individualized_educational_plan: {
          iep_review_dates_attributes: {
            '0' => { id: first_review.id, _destroy: '1' },
            '1' => { id: second_review.id, _destroy: '1' }
          }
        }
      }

      reviews = assigns(:individualized_educational_plan).iep_review_dates
      blocked_message = I18n.t('activerecord.errors.models.iep_review_date.attributes.review_date.cannot_remove')
      expect(reviews.detect { |review| review.id == first_review.id }.errors[:review_date]).to include(blocked_message)
      expect(reviews.detect { |review| review.id == second_review.id }.errors[:review_date]).to include(blocked_message)
    end

    it 'destroys a persisted section line when its form is cleared, releasing the review' do
      plan = create(:individualized_educational_plan)
      review_date = create(:iep_review_date, iep: plan)
      planning = create(:iep_curricular_planning, iep: plan, iep_review_date: review_date, long_term_goal: 'Meta')

      patch :update, params: {
        locale: 'pt-BR', id: plan.id,
        individualized_educational_plan: {
          iep_curricular_plannings_attributes: { '0' => {
            id: planning.id, long_term_goal: '', stage_objectives: '', skills_to_develop: '', methodologies: '',
            instructional_accommodation_option_ids: '', environmental_accommodation_option_ids: '',
            assessment_accommodation_option_ids: ''
          } }
        }
      }

      expect(IepCurricularPlanning.exists?(planning.id)).to eq(false)
      expect(review_date.reload.destroy).to be_truthy
    end

    it 'updates the plan and redirects to the index' do
      plan = create(:individualized_educational_plan)

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, individualized_educational_plan: { characterization: 'Atualizado' }
      }

      expect(plan.reload.characterization).to eq('Atualizado')
      expect(response).to redirect_to(individualized_educational_plans_path)
    end
  end
end
