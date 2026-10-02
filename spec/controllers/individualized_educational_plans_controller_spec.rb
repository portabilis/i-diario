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

  # Enturma o aluno numa turma (left_at '' = aberta). O acesso ao PEI deriva da matrícula.
  def enroll(student, classroom, left_at: '')
    cg = create(:classrooms_grade, classroom: classroom)
    se = create(:student_enrollment, student: student)
    create(:student_enrollment_classroom, student_enrollment: se, classrooms_grade: cg, left_at: left_at)
  end

  describe 'GET #index' do
    context 'as an admin/employee' do
      let(:classroom) { create(:classroom, year: Date.current.year) }

      before do
        allow(controller).to receive(:current_user_classroom).and_return(classroom)
        allow(controller).to receive(:current_school_year).and_return(Date.current.year)
      end

      def plan_enrolled_in(classroom)
        plan = create(:individualized_educational_plan, year: Date.current.year)
        enroll(plan.student, classroom)
        plan
      end

      it 'lists only plans of students enrolled in the selected classroom' do
        target = plan_enrolled_in(classroom)
        create(:individualized_educational_plan, year: Date.current.year)

        get :index, params: { locale: 'pt-BR' }

        expect(response).to have_http_status(:ok)
        expect(assigns(:individualized_educational_plans)).to contain_exactly(target)
      end

      it 'omits archived plans' do
        target = plan_enrolled_in(classroom)
        archived = plan_enrolled_in(classroom)
        archived.discard

        get :index, params: { locale: 'pt-BR' }

        expect(assigns(:individualized_educational_plans)).to contain_exactly(target)
      end

      it 'filters by status' do
        in_progress = plan_enrolled_in(classroom)
        plan_enrolled_in(classroom).update_column(:finalized_at, Time.current)

        get :index, params: { locale: 'pt-BR', filter: { by_status: IepStatuses::IN_PROGRESS } }

        expect(assigns(:individualized_educational_plans)).to contain_exactly(in_progress)
      end

      it 'filters by student' do
        target = plan_enrolled_in(classroom)
        plan_enrolled_in(classroom)

        get :index, params: { locale: 'pt-BR', filter: { by_student_id: target.student_id } }

        expect(assigns(:individualized_educational_plans)).to contain_exactly(target)
      end

      it 'paginates the plans (default 10 per page)' do
        11.times { plan_enrolled_in(classroom) }

        get :index, params: { locale: 'pt-BR', page: 1 }
        first_page_ids = assigns(:individualized_educational_plans).map(&:id)

        get :index, params: { locale: 'pt-BR', page: 2 }
        second_page = assigns(:individualized_educational_plans)

        expect(second_page.to_a.size).to eq(1)
        expect(first_page_ids).not_to include(second_page.first.id)
      end
    end

    context 'without a classroom selected in the profile' do
      before { allow(controller).to receive(:current_user_classroom).and_return(nil) }

      it 'redirects to the root path' do
        get :index, params: { locale: 'pt-BR' }

        expect(response).to redirect_to(root_path)
      end
    end

    # O index exige contexto de professor para todos os perfis (before_action
    # require_current_teacher). Fixa a decisão: sem current_teacher, redireciona.
    context 'without a current teacher' do
      before do
        allow(controller).to receive(:require_current_teacher).and_call_original
        allow(controller).to receive(:current_teacher).and_return(nil)
        allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))
      end

      it 'redirects to the root path' do
        get :index, params: { locale: 'pt-BR' }

        expect(response).to redirect_to(root_path)
      end
    end

    context 'when not authorized (Pundit)' do
      before do
        allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))
        allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
      end

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
        target = create(:individualized_educational_plan, year: Date.current.year)
        enroll(target.student, classroom)
        other = create(:individualized_educational_plan, year: Date.current.year)
        enroll(other.student, other_classroom)

        get :index, params: { locale: 'pt-BR' }

        expect(response).to have_http_status(:ok)
        expect(assigns(:individualized_educational_plans)).to contain_exactly(target)
      end

      it 'lists all teacher classrooms when the classroom filter is cleared' do
        other_classroom = create(:classroom, unity: selected_unity, year: Date.current.year)
        create(:teacher_discipline_classroom, teacher: teacher, classroom: other_classroom, year: Date.current.year)
        plan_in_profile = create(:individualized_educational_plan, year: Date.current.year)
        enroll(plan_in_profile.student, classroom)
        plan_in_other = create(:individualized_educational_plan, year: Date.current.year)
        enroll(plan_in_other.student, other_classroom)

        get :index, params: { locale: 'pt-BR', filter: { by_classroom_id: '' } }

        expect(assigns(:individualized_educational_plans)).to contain_exactly(plan_in_profile, plan_in_other)
      end

      it 'renders empty when the teacher has no linked classrooms' do
        allow(TeacherClassroomAndDisciplineFetcher).to receive(:fetch!).and_return(nil)
        create(:individualized_educational_plan)

        get :index, params: { locale: 'pt-BR' }

        expect(response).to have_http_status(:ok)
        expect(assigns(:individualized_educational_plans)).to be_empty
      end
    end
  end

  # O professor só edita as seções 4/5 do próprio componente. A trava de escopo
  # (authorize_teacher_component_scope!) é um método próprio do controller (não o authorize
  # do Pundit, que é stubado aqui), então é de fato exercitada.
  describe 'PATCH #update as a teacher' do
    let(:teacher) { create(:teacher) }
    let(:unity) { create(:unity) }
    let(:classroom) { create(:classroom, unity: unity, year: Date.current.year) }
    let(:knowledge_area) { create(:knowledge_area) }
    let(:own_discipline) { create(:discipline, knowledge_area: knowledge_area) }
    let(:other_discipline) { create(:discipline) }
    let(:plan) { create(:individualized_educational_plan, characterization: 'Original') }
    let(:review) { create(:iep_review_date, iep: plan, review_date: Date.current) }
    let!(:own_line) do
      create(:iep_curricular_planning, iep: plan, iep_review_date: review,
                                       discipline: own_discipline, long_term_goal: 'Meta')
    end

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(user).to receive(:current_role_is_admin_or_employee?).and_return(false)
      allow(controller).to receive(:current_teacher).and_return(teacher)
      allow(controller).to receive(:current_unity).and_return(unity)
      allow(controller).to receive(:current_school_year).and_return(Date.current.year)
      allow(controller).to receive(:current_user_classroom).and_return(classroom)
      create(:teacher_discipline_classroom, teacher: teacher, classroom: classroom,
                                            discipline: own_discipline, year: Date.current.year)
      # aluno do plano enturmado (aberto) na turma do professor → PEI acessível e editável
      create(:student_enrollment_classroom,
             student_enrollment: create(:student_enrollment, student: plan.student),
             classrooms_grade: create(:classrooms_grade, classroom: classroom))
    end

    it 'updates a section 4/5 line of the own component' do
      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: {
          iep_curricular_plannings_attributes: { '0' => { id: own_line.id, long_term_goal: 'Meta revisada' } }
        }
      }

      expect(response).to redirect_to(individualized_educational_plans_path)
      expect(own_line.reload.long_term_goal).to eq('Meta revisada')
    end

    it 'ignores fields outside sections 4/5 (strong parameters)' do
      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: {
          characterization: 'Invadido',
          uses_medication: 'true',
          iep_medications_attributes: { '0' => { name: 'Invadido' } },
          iep_curricular_plannings_attributes: { '0' => { id: own_line.id, long_term_goal: 'Meta ok' } }
        }
      }

      expect(plan.reload.characterization).to eq('Original')
      expect(plan.uses_medication).to be_nil
      expect(plan.iep_medications).to be_empty
      expect(own_line.reload.long_term_goal).to eq('Meta ok')
    end

    # O professor não edita a etapa 3: um "Sim" salvo sem medicamento não pode travar o save dele.
    it 'saves the own line even when the plan has a "yes" medication answer without medications' do
      plan.update_column(:uses_medication, true)

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: {
          iep_curricular_plannings_attributes: { '0' => { id: own_line.id, long_term_goal: 'Meta revisada' } }
        }
      }

      expect(response).to redirect_to(individualized_educational_plans_path)
      expect(own_line.reload.long_term_goal).to eq('Meta revisada')
    end

    it 'blocks editing a line of another component and does not persist it' do
      other_line = create(:iep_curricular_planning, iep: plan, iep_review_date: review,
                                                    discipline: other_discipline, long_term_goal: 'De outro')

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: {
          iep_curricular_plannings_attributes: { '0' => { id: other_line.id, long_term_goal: 'Invadido' } }
        }
      }

      expect(response).to redirect_to(root_path)
      expect(other_line.reload.long_term_goal).to eq('De outro')
    end

    it 'saves a draft of the own line without publishing a version' do
      patch :update, params: {
        locale: 'pt-BR', id: plan.id, draft: '1',
        individualized_educational_plan: {
          iep_curricular_plannings_attributes: { '0' => { id: own_line.id, long_term_goal: 'Meta revisada' } }
        }
      }

      expect(response).to have_http_status(:ok)
      expect(own_line.reload.long_term_goal).to eq('Meta revisada')
      expect(plan.iep_versions.count).to eq(0)
    end

    it 'answers the draft of a line of another component with 403 in JSON and does not persist it' do
      other_line = create(:iep_curricular_planning, iep: plan, iep_review_date: review,
                                                    discipline: other_discipline, long_term_goal: 'De outro')

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, draft: '1',
        individualized_educational_plan: {
          iep_curricular_plannings_attributes: { '0' => { id: other_line.id, long_term_goal: 'Invadido' } }
        }
      }

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)['errors'])
        .to include(I18n.t('individualized_educational_plans.draft.not_authorized'))
      expect(other_line.reload.long_term_goal).to eq('De outro')
    end

    it 'does not update a plan of a classroom the teacher is not linked to' do
      other_plan = create(:individualized_educational_plan)

      patch :update, params: {
        locale: 'pt-BR', id: other_plan.id, version_name: 'Versão 1',
        individualized_educational_plan: {
          iep_curricular_plannings_attributes: { '0' => { discipline_id: own_discipline.id, long_term_goal: 'x' } }
        }
      }

      expect(response).to redirect_to(individualized_educational_plans_path)
      expect(other_plan.iep_versions.count).to eq(0)
    end

    it 'restricts the editable components to the teacher own components on edit' do
      get :edit, params: { locale: 'pt-BR', id: plan.id }

      expect(assigns(:disciplines).map(&:id)).to contain_exactly(own_discipline.id)
      expect(assigns(:editable_component_scope)).to be_present
    end
  end

  describe 'DELETE #destroy' do
    before do
      allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))
      allow(controller).to receive(:accessible_plans).and_return(IndividualizedEducationalPlan.kept)
      allow(controller).to receive(:plan_editable?).and_return(true)
    end

    it 'archives the plan and redirects to the index' do
      plan = create(:individualized_educational_plan)

      expect {
        delete :destroy, params: { locale: 'pt-BR', id: plan.id }
      }.not_to change(IndividualizedEducationalPlan, :count)

      expect(plan.reload).to be_discarded
      expect(response).to redirect_to(individualized_educational_plans_path)
    end

    it 'preserves the published versions and the section records when archiving' do
      plan = create(:individualized_educational_plan)
      review_date = create(:iep_review_date, iep: plan)
      planning = create(:iep_curricular_planning, iep: plan, iep_review_date: review_date, long_term_goal: 'Meta')
      evaluation = create(:iep_periodic_evaluation, iep: plan, iep_review_date: review_date,
                                                    acquired_skills: 'Habilidades')
      version = create(:iep_version, :current, iep: plan)

      delete :destroy, params: { locale: 'pt-BR', id: plan.id }

      expect(plan.reload).to be_discarded
      expect(plan.iep_versions).to contain_exactly(version)
      expect(plan.iep_review_dates).to contain_exactly(review_date)
      expect(plan.iep_curricular_plannings).to contain_exactly(planning)
      expect(plan.iep_periodic_evaluations).to contain_exactly(evaluation)
      expect(response).to redirect_to(individualized_educational_plans_path)
    end

    # A poda de linhas vazias é do save do formulário; no arquivamento ela apagaria de vez a linha
    # que o arquivamento existe para preservar.
    it 'preserves a section line without content when archiving' do
      plan = create(:individualized_educational_plan)
      review_date = create(:iep_review_date, iep: plan)
      empty_line = create(:iep_curricular_planning, iep: plan, iep_review_date: review_date)

      delete :destroy, params: { locale: 'pt-BR', id: plan.id }

      expect(plan.reload).to be_discarded
      expect(plan.iep_curricular_plannings).to contain_exactly(empty_line)
    end

    it 'does not archive a plan from a classroom the user is not linked to' do
      allow(controller).to receive(:accessible_plans).and_call_original
      plan = create(:individualized_educational_plan)

      delete :destroy, params: { locale: 'pt-BR', id: plan.id }

      expect(plan.reload).not_to be_discarded
      expect(response).to redirect_to(individualized_educational_plans_path)
    end

    it 'does not archive a plan the user can no longer edit (visible only by authorship)' do
      allow(controller).to receive(:plan_editable?).and_return(false)
      plan = create(:individualized_educational_plan)

      delete :destroy, params: { locale: 'pt-BR', id: plan.id }

      expect(plan.reload).not_to be_discarded
      expect(response).to redirect_to(individualized_educational_plan_path(plan))
    end

    # O discard salva com validação. update_column (e não save(validate: false)) para produzir a
    # linha inválida sem passar pelas validações que justamente impedem esse estado pela tela.
    it 'warns with the reason instead of announcing an archiving that did not happen' do
      plan = create(:individualized_educational_plan)
      plan.update_column(:elaborated_at, Date.new(plan.year - 1, 3, 10))

      delete :destroy, params: { locale: 'pt-BR', id: plan.id }

      expect(plan.reload).not_to be_discarded
      expect(flash[:alert]).to start_with('Não foi possível excluir este PEI:')
      expect(flash[:alert]).to include('Data de elaboração', "ano letivo do plano (#{plan.year})")
      expect(response).to redirect_to(individualized_educational_plans_path)
    end
  end

  describe 'GET #fetch_students_by_classroom' do
    let(:classroom) { create(:classroom) }

    before do
      allow(controller).to receive(:current_user_classroom).and_return(classroom)
      allow(controller).to receive(:accessible_classrooms).and_return([classroom])
      allow(controller).to receive(:current_school_year).and_return(Date.current.year)
    end

    it 'excludes a student whose only plan in the classroom is from another school year' do
      current = create(:individualized_educational_plan)
      enroll(current.student, classroom)
      previous = create(:individualized_educational_plan, year: Date.current.year - 1,
                                                          elaborated_at: Date.new(Date.current.year - 1, 3, 10))
      enroll(previous.student, classroom)

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: classroom.id, format: :json }

      expect(JSON.parse(response.body)).to contain_exactly(
        'id' => current.student_id, 'name' => current.student.name
      )
    end

    it 'excludes a student whose only plan in the classroom was archived' do
      current = create(:individualized_educational_plan)
      enroll(current.student, classroom)
      archived = create(:individualized_educational_plan)
      enroll(archived.student, classroom)
      archived.discard

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: classroom.id, format: :json }

      expect(JSON.parse(response.body)).to contain_exactly(
        'id' => current.student_id, 'name' => current.student.name
      )
    end

    it 'returns only students that have a plan and are enrolled in the classroom' do
      plan = create(:individualized_educational_plan)
      enroll(plan.student, classroom)
      other = create(:individualized_educational_plan) # aluno enturmado em outra turma
      enroll(other.student, create(:classroom))

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: classroom.id, format: :json }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to contain_exactly('id' => plan.student_id, 'name' => plan.student.name)
    end

    it 'excludes a student without a plan in the classroom' do
      plan = create(:individualized_educational_plan)
      enroll(plan.student, classroom)
      enroll(create(:student), classroom) # aluno enturmado mas sem PEI — não deve ser listado

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: classroom.id, format: :json }

      expect(JSON.parse(response.body)).to contain_exactly('id' => plan.student_id, 'name' => plan.student.name)
    end

    it 'sorts the students by name' do
      zilda = create(:student, name: 'Zilda')
      ana = create(:student, name: 'Ana')
      [zilda, ana].each do |s|
        create(:individualized_educational_plan, student: s)
        enroll(s, classroom)
      end

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: classroom.id, format: :json }

      expect(JSON.parse(response.body).map { |s| s['name'] }).to eq(%w[Ana Zilda])
    end

    it 'returns an empty list for a classroom the user cannot access' do
      other_classroom = create(:classroom)
      plan = create(:individualized_educational_plan)
      enroll(plan.student, other_classroom)

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: other_classroom.id, format: :json }

      expect(JSON.parse(response.body)).to eq([])
    end

    it 'returns an empty list when no classroom is given' do
      create(:individualized_educational_plan)

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: '', format: :json }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'redirects to the root path when not authorized (Pundit)' do
      allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: classroom.id, format: :json }

      expect(response).to redirect_to(root_path)
    end
  end

  # Select de aluno na criação filtra pelos enturmados na turma do perfil na DATA DE
  # ELABORAÇÃO escolhida (não hoje) — o usuário escolhe a data primeiro.
  describe 'GET #students_by_elaboration_date' do
    let(:classroom) { create(:classroom) }

    before do
      allow(controller).to receive(:current_user_classroom).and_return(classroom)
      allow(controller).to receive(:current_school_year).and_return(Date.current.year)
    end

    def enroll(student, joined_at:, left_at: '')
      cg = create(:classrooms_grade, classroom: classroom)
      se = create(:student_enrollment, student: student)
      create(:student_enrollment_classroom, student_enrollment: se, classrooms_grade: cg,
                                            joined_at: joined_at, left_at: left_at)
    end

    it 'lists only students enrolled in the profile classroom on the elaboration date' do
      current = create(:student)
      enroll(current, joined_at: '2026-02-01', left_at: '')                # aberta, cobre a data
      left_before = create(:student)
      enroll(left_before, joined_at: '2026-02-01', left_at: '2026-03-01')  # saiu antes da data
      joined_after = create(:student)
      enroll(joined_after, joined_at: '2026-05-01', left_at: '')           # entrou depois da data

      get :students_by_elaboration_date, params: {
        locale: 'pt-BR', elaborated_at: '2026-04-10', format: :json
      }

      ids = JSON.parse(response.body)['students'].map { |student| student['id'] }
      expect(ids).to contain_exactly(current.id)
    end

    it 'warns right away that a future elaboration date is not allowed' do
      get :students_by_elaboration_date, params: {
        locale: 'pt-BR', elaborated_at: (Date.current + 1).to_s, format: :json
      }

      expect(JSON.parse(response.body)['calendar_error']).to eq(I18n.t('errors.messages.not_in_future'))
    end

    # O aviso tem que dar o motivo real, não "deve ser um dia letivo" do calendário daquele ano.
    it 'warns right away that the date is outside the plan school year' do
      get :students_by_elaboration_date, params: {
        locale: 'pt-BR', elaborated_at: Date.new(Date.current.year - 1, 6, 3).to_s, format: :json
      }

      expect(JSON.parse(response.body)['calendar_error']).to eq(
        I18n.t(IndividualizedEducationalPlanElaborationDayCheck::NOT_IN_PLAN_YEAR_KEY, year: Date.current.year)
      )
    end

    it 'falls back to today when the date is invalid' do
      today_student = create(:student)
      enroll(today_student, joined_at: 1.year.ago.to_date.to_s, left_at: '')

      get :students_by_elaboration_date, params: { locale: 'pt-BR', elaborated_at: 'xx', format: :json }

      ids = JSON.parse(response.body)['students'].map { |student| student['id'] }
      expect(ids).to contain_exactly(today_student.id)
    end

    # O status da matrícula é ATUAL: um aluno transferido HOJE ainda estava na turma ONTEM, então
    # numa data anterior à saída ele deve aparecer (não filtrar por status_attending).
    it 'includes a student enrolled on the date even if transferred afterwards' do
      transferred = create(:student)
      cg = create(:classrooms_grade, classroom: classroom)
      se = create(:student_enrollment, student: transferred, status: StudentEnrollmentStatus::TRANSFERRED)
      create(:student_enrollment_classroom, student_enrollment: se, classrooms_grade: cg,
                                            joined_at: '2026-02-01', left_at: '2026-08-04')

      get :students_by_elaboration_date, params: { locale: 'pt-BR', elaborated_at: '2026-08-04', format: :json }
      expect(JSON.parse(response.body)['students']).to be_empty

      get :students_by_elaboration_date, params: { locale: 'pt-BR', elaborated_at: '2026-08-03', format: :json }
      expect(JSON.parse(response.body)['students'].map { |s| s['id'] }).to contain_exactly(transferred.id)
    end

    it 'reports calendar_error when the date is not a valid school calendar day' do
      allow(IndividualizedEducationalPlanElaborationDayCheck).to receive(:error_for)
        .and_return(I18n.t('errors.messages.is_not_between_steps'))

      get :students_by_elaboration_date, params: { locale: 'pt-BR', elaborated_at: '2026-04-10', format: :json }

      expect(JSON.parse(response.body)['calendar_error']).to eq(I18n.t('errors.messages.is_not_between_steps'))
    end
  end

  # Laudos: a fonte é o cadastro do aluno no i-Educar. Endpoints próprios porque a tela de
  # versão publicada não busca o restante dos dados (congelados) mas mostra o laudo atual.
  describe 'medical reports' do
    let(:classroom) { create(:classroom) }
    # Acesso por plan_id deriva da matrícula (accessible_plans): o aluno do plano precisa estar
    # enturmado na turma do perfil.
    let(:plan) do
      p = create(:individualized_educational_plan)
      enroll(p.student, classroom)
      p
    end

    before do
      allow(controller).to receive(:current_user_classroom).and_return(classroom)
      allow(controller).to receive(:current_school_year).and_return(Date.current.year)
    end

    def enroll(student, target_classroom)
      classrooms_grade = create(:classrooms_grade, classroom: target_classroom)
      enrollment = create(:student_enrollment, student: student)
      create(:student_enrollment_classroom, student_enrollment: enrollment,
                                            classrooms_grade: classrooms_grade)
    end

    # Na criação do PEI o plano ainda não existe: o form consulta por student_id, e quem
    # autoriza é o vínculo do aluno com a turma do perfil.
    describe 'by student (creation, without plan_id)' do
      it 'returns the reports of a student enrolled in the profile classroom' do
        student = create(:student)
        enroll(student, classroom)
        expect(IndividualizedEducationalPlanPrefill).to receive(:medical_reports_data)
          .with(student)
          .and_return(medical_reports: [], medical_reports_unavailable: false)

        get :medical_reports, params: { locale: 'pt-BR', student_id: student.id, format: :json }

        expect(response).to have_http_status(:ok)
      end

      it 'does not return reports of a student outside the profile classroom' do
        other_student = create(:student) # não enturmado nas turmas do perfil
        expect(IndividualizedEducationalPlanPrefill).not_to receive(:medical_reports_data)

        get :medical_reports, params: { locale: 'pt-BR', student_id: other_student.id, format: :json }

        expect(response).to have_http_status(:not_found)
      end

      it 'does not open the report of a student outside the profile classroom' do
        other_student = create(:student)
        expect(IndividualizedEducationalPlanPrefill).not_to receive(:medical_report_lookup)

        get :open_medical_report, params: {
          locale: 'pt-BR', student_id: other_student.id, name: 'laudo.pdf'
        }

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET #medical_reports' do
      it 'returns the reports of the plan student' do
        expect(IndividualizedEducationalPlanPrefill).to receive(:medical_reports_data)
          .with(plan.student)
          .and_return(medical_reports: [{ name: 'laudo.pdf', sent_at: '27/04/2023' }],
                      medical_reports_unavailable: false)

        get :medical_reports, params: { locale: 'pt-BR', plan_id: plan.id, format: :json }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(
          'medical_reports' => [{ 'name' => 'laudo.pdf', 'sent_at' => '27/04/2023' }],
          'medical_reports_unavailable' => false
        )
      end

      it 'does not return reports of a plan outside the user classrooms' do
        other_plan = create(:individualized_educational_plan)
        expect(IndividualizedEducationalPlanPrefill).not_to receive(:medical_reports_data)

        get :medical_reports, params: { locale: 'pt-BR', plan_id: other_plan.id, format: :json }

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET #open_medical_report' do
      it 'redirects to the url resolved at click time' do
        allow(IndividualizedEducationalPlanPrefill).to receive(:medical_report_lookup)
          .with(plan.student, 'laudo.pdf', '2023-04-27T12:36:18.000000Z')
          .and_return(url: 'https://s3.amazonaws.com/laudo-assinado', unavailable: false)

        get :open_medical_report, params: {
          locale: 'pt-BR', plan_id: plan.id, name: 'laudo.pdf',
          created_at: '2023-04-27T12:36:18.000000Z'
        }

        expect(response).to redirect_to('https://s3.amazonaws.com/laudo-assinado')
      end

      it 'explains that the report is no longer in the student record' do
        allow(IndividualizedEducationalPlanPrefill).to receive(:medical_report_lookup)
          .and_return(url: nil, unavailable: false)

        get :open_medical_report, params: { locale: 'pt-BR', plan_id: plan.id, name: 'laudo.pdf' }

        expect(response).to redirect_to(individualized_educational_plans_path)
        expect(flash[:alert]).to eq(I18n.t('individualized_educational_plans.flash.medical_report_gone'))
      end

      it 'distinguishes an unreachable i-Educar from a report that was removed' do
        allow(IndividualizedEducationalPlanPrefill).to receive(:medical_report_lookup)
          .and_return(url: nil, unavailable: true)

        get :open_medical_report, params: { locale: 'pt-BR', plan_id: plan.id, name: 'laudo.pdf' }

        expect(response).to redirect_to(individualized_educational_plans_path)
        expect(flash[:alert]).to eq(
          I18n.t('individualized_educational_plans.flash.medical_report_unavailable')
        )
      end

      it 'does not open the report of a plan outside the user classrooms' do
        other_plan = create(:individualized_educational_plan)
        expect(IndividualizedEducationalPlanPrefill).not_to receive(:medical_report_lookup)

        get :open_medical_report, params: {
          locale: 'pt-BR', plan_id: other_plan.id, name: 'laudo.pdf'
        }

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'POST #upload_medical_report' do
      let(:file) do
        Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'image.png'), 'image/png')
      end
      let(:success_result) do
        IeducarApi::MedicalReports::Result.new(true, 'Laudo salvo com sucesso.', :ok)
      end

      before do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:current_role_is_admin_or_employee?).and_return(true)
      end

      it 'sends the file of the plan student to the i-Educar' do
        expect(IeducarApi::MedicalReports).to receive(:upload)
          .with(student_api_code: plan.student.api_code, file: duck_type(:original_filename, :read))
          .and_return(success_result)

        post :upload_medical_report, params: { locale: 'pt-BR', plan_id: plan.id, file: file }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq('message' => 'Laudo salvo com sucesso.')
      end

      it 'sends the file of an enrolled student during creation (without plan_id)' do
        student = create(:student)
        enroll(student, classroom)
        expect(IeducarApi::MedicalReports).to receive(:upload)
          .with(student_api_code: student.api_code, file: duck_type(:original_filename, :read))
          .and_return(success_result)

        post :upload_medical_report, params: { locale: 'pt-BR', student_id: student.id, file: file }

        expect(response).to have_http_status(:ok)
      end

      # A seção 1 (onde mora o laudo) é somente leitura para o professor: a trava da view
      # é reforçada aqui no servidor.
      it 'does not allow a teacher to upload' do
        allow(user).to receive(:current_role_is_admin_or_employee?).and_return(false)
        expect(IeducarApi::MedicalReports).not_to receive(:upload)

        post :upload_medical_report, params: { locale: 'pt-BR', plan_id: plan.id, file: file }

        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)).to eq(
          'message' => 'Somente administradores e servidores podem enviar laudos.'
        )
      end

      it 'does not upload to a plan outside the user classrooms' do
        other_plan = create(:individualized_educational_plan)
        expect(IeducarApi::MedicalReports).not_to receive(:upload)

        post :upload_medical_report, params: { locale: 'pt-BR', plan_id: other_plan.id, file: file }

        expect(response).to have_http_status(:not_found)
      end

      it 'does not upload for a student outside the profile classroom (creation)' do
        other_student = create(:student)
        expect(IeducarApi::MedicalReports).not_to receive(:upload)

        post :upload_medical_report, params: { locale: 'pt-BR', student_id: other_student.id, file: file }

        expect(response).to have_http_status(:not_found)
      end

      it 'does not upload when the plan is read-only (student no longer attending)' do
        allow(controller).to receive(:plan_editable?).and_return(false)
        expect(IeducarApi::MedicalReports).not_to receive(:upload)

        post :upload_medical_report, params: { locale: 'pt-BR', plan_id: plan.id, file: file }

        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)).to eq(
          'message' => I18n.t('individualized_educational_plans.flash.read_only_transferred')
        )
      end

      it 'does not upload when the student has no i-Educar api_code' do
        student = create(:student, api: false, api_code: '')
        enroll(student, classroom)
        expect(IeducarApi::MedicalReports).not_to receive(:upload)

        post :upload_medical_report, params: { locale: 'pt-BR', student_id: student.id, file: file }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq(
          'message' => 'O aluno não possui vínculo com o cadastro do i-Educar.'
        )
      end

      it 'relays the failure message and status from the service' do
        failure = IeducarApi::MedicalReports::Result.new(
          false, 'Não foi possível conectar ao i-Educar. Tente novamente em instantes.', :bad_gateway
        )
        allow(IeducarApi::MedicalReports).to receive(:upload).and_return(failure)

        post :upload_medical_report, params: { locale: 'pt-BR', plan_id: plan.id, file: file }

        expect(response).to have_http_status(:bad_gateway)
        expect(JSON.parse(response.body)).to eq(
          'message' => 'Não foi possível conectar ao i-Educar. Tente novamente em instantes.'
        )
      end
    end
  end

  describe 'GET #student_data' do
    let(:classroom) { create(:classroom) }

    before do
      allow(controller).to receive(:current_user_classroom).and_return(classroom)
      allow(controller).to receive(:current_school_year).and_return(Date.current.year)
    end

    # Enturma o aluno numa turma do perfil. left_at '' = aberta (permitido); data passada =
    # transferido (não permitido em #student_data / na criação).
    def enroll(student, target_classroom, left_at: '')
      classrooms_grade = create(:classrooms_grade, classroom: target_classroom)
      enrollment = create(:student_enrollment, student: student)
      create(:student_enrollment_classroom, student_enrollment: enrollment,
                                            classrooms_grade: classrooms_grade, left_at: left_at)
    end

    # Consistente com o select: valida o aluno pela enturmação da DATA DE ELABORAÇÃO, não de hoje —
    # um aluno transferido depois da data aparece no select e o prefill não pode estourar.
    it 'returns data for a student enrolled on the elaboration date even if transferred afterwards' do
      student = create(:student)
      cg = create(:classrooms_grade, classroom: classroom)
      se = create(:student_enrollment, student: student, status: StudentEnrollmentStatus::TRANSFERRED)
      create(:student_enrollment_classroom, student_enrollment: se, classrooms_grade: cg,
                                            joined_at: '2026-02-01', left_at: '2026-08-04')
      allow(IndividualizedEducationalPlanPrefill).to receive(:student_data).and_return(guardians: 'Maria')

      get :student_data, params: {
        locale: 'pt-BR', student_id: student.id, elaborated_at: '2026-08-03', format: :json
      }
      expect(response).to have_http_status(:ok)

      get :student_data, params: {
        locale: 'pt-BR', student_id: student.id, elaborated_at: '2026-08-04', format: :json
      }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns the full identification contract (all fields form.js consumes) plus the flag' do
      student = create(:student)
      enroll(student, classroom)
      expect(IndividualizedEducationalPlanPrefill).to receive(:student_data)
        .with(kind_of(Student), classroom: classroom)
        .and_return(birth_date: '10/03/2015', diagnosis: 'TEA', guardians: 'Maria Silva',
                    shift: 'Matutino',
                    medical_reports: [{ name: 'laudo.pdf', sent_at: '27/04/2023',
                                        created_at: '2023-04-27T12:36:18.000000Z' }],
                    medical_reports_unavailable: false)

      get :student_data, params: { locale: 'pt-BR', student_id: student.id, format: :json }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        'birth_date' => '10/03/2015', 'diagnosis' => 'TEA', 'guardians' => 'Maria Silva',
        'shift' => 'Matutino',
        'medical_reports' => [{ 'name' => 'laudo.pdf', 'sent_at' => '27/04/2023',
                                'created_at' => '2023-04-27T12:36:18.000000Z' }],
        'medical_reports_unavailable' => false,
        'has_existing_plan' => false
      )
    end

    it 'does not return data for a student outside the permitted classrooms' do
      other_student = create(:student) # não enturmado nas turmas do perfil
      expect(IndividualizedEducationalPlanPrefill).not_to receive(:student_data)

      get :student_data, params: { locale: 'pt-BR', student_id: other_student.id, format: :json }

      expect(response).to have_http_status(:not_found)
    end

    it 'does not return data for a transferred student (closed enrollment)' do
      student = create(:student)
      enroll(student, classroom, left_at: 1.month.ago.to_date.to_s)
      expect(IndividualizedEducationalPlanPrefill).not_to receive(:student_data)

      get :student_data, params: { locale: 'pt-BR', student_id: student.id, format: :json }

      expect(response).to have_http_status(:not_found)
    end

    it 'flags when the student already has a plan for the year' do
      allow(IndividualizedEducationalPlanPrefill).to receive(:student_data).and_return({})
      plan = create(:individualized_educational_plan, year: Date.current.year)
      enroll(plan.student, classroom)

      get :student_data, params: { locale: 'pt-BR', student_id: plan.student_id, format: :json }

      expect(JSON.parse(response.body)['has_existing_plan']).to eq(true)
    end

    it 'does not flag an archived plan as existing' do
      allow(IndividualizedEducationalPlanPrefill).to receive(:student_data).and_return({})
      plan = create(:individualized_educational_plan, year: Date.current.year)
      enroll(plan.student, classroom)
      plan.discard

      get :student_data, params: { locale: 'pt-BR', student_id: plan.student_id, format: :json }

      expect(JSON.parse(response.body)['has_existing_plan']).to eq(false)
    end

    it 'ignores the plan being edited when flagging (plan_id)' do
      allow(IndividualizedEducationalPlanPrefill).to receive(:student_data).and_return({})
      plan = create(:individualized_educational_plan, year: Date.current.year)
      enroll(plan.student, classroom)

      get :student_data, params: {
        locale: 'pt-BR', student_id: plan.student_id, plan_id: plan.id, format: :json
      }

      expect(JSON.parse(response.body)['has_existing_plan']).to eq(false)
    end

    # Congelamento: quem só vê o plano por autoria (aluno não cursa mais a turma) não pode puxar
    # os dados VIVOS do aluno pelo prefill — só a versão congelada.
    it 'forbids the prefill for a plan visible only by authorship (student no longer attending)' do
      plan = create(:individualized_educational_plan)
      create(:iep_version, iep: plan, classroom_id: classroom.id, published_at: Time.current, active: true,
                           content: { 'identification' => { 'student_name' => plan.student.name } })
      allow(IndividualizedEducationalPlanPrefill).to receive(:student_data).and_return(guardians: 'Maria Silva')

      get :student_data, params: {
        locale: 'pt-BR', student_id: plan.student_id, plan_id: plan.id, format: :json
      }

      expect(response).to have_http_status(:forbidden)
    end

    # O congelamento vale pelo aluno: sem isto, omitir o plan_id e mandar data retroativa
    # devolvia os dados vivos de quem o usuário só pode ver congelado.
    it 'forbids the prefill of a frozen plan even when plan_id is omitted' do
      student = create(:student)
      cg = create(:classrooms_grade, classroom: classroom)
      se = create(:student_enrollment, student: student, status: StudentEnrollmentStatus::TRANSFERRED)
      create(:student_enrollment_classroom, student_enrollment: se, classrooms_grade: cg,
                                            joined_at: '2026-02-01', left_at: '2026-08-04')
      plan = create(:individualized_educational_plan, student: student, year: Date.current.year)
      create(:iep_version, iep: plan, classroom_id: classroom.id, published_at: Time.current, active: true,
                           content: { 'identification' => { 'student_name' => student.name } })
      expect(IndividualizedEducationalPlanPrefill).not_to receive(:student_data)

      get :student_data, params: {
        locale: 'pt-BR', student_id: student.id, elaborated_at: '2026-08-03', format: :json
      }

      expect(response).to have_http_status(:forbidden)
    end

    it 'does not return data through a plan outside the user classrooms (plan_id)' do
      other_plan = create(:individualized_educational_plan)
      expect(IndividualizedEducationalPlanPrefill).not_to receive(:student_data)

      get :student_data, params: {
        locale: 'pt-BR', student_id: other_plan.student_id, plan_id: other_plan.id, format: :json
      }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 're-rendering the form after a failure' do
    let(:unity) { create(:unity) }
    let(:classroom) { create(:classroom, unity: unity) }

    before do
      allow(controller).to receive(:current_user_classroom).and_return(classroom)
      allow(controller).to receive(:student_permitted_for_creation?).and_return(true)
      allow(controller).to receive(:current_school_year).and_return(Date.current.year)
      allow(IeducarApiConfiguration).to receive(:current).and_return(double(to_api: {}))
      allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {}))
    end

    # No modelo novo o contexto (escola/turma) do formulário de criação é derivado da turma
    # do perfil, não de unity_id/classroom_id enviados.
    it 'repopulates the display fields from the profile classroom on a create validation failure' do
      student = create(:student)
      create(:individualized_educational_plan, student: student, year: Date.current.year) # dispara duplicidade

      post :create, params: {
        locale: 'pt-BR', version_name: 'Versão 1',
        individualized_educational_plan: {
          student_id: student.id, year: Date.current.year, elaborated_at: Date.current
        }
      }

      expect(response).to render_template(:new)
      plan = assigns(:individualized_educational_plan)
      expect(plan.unity_name).to eq(unity.name)
      expect(plan.classroom_name).to eq(classroom.description)
    end
  end

  describe 'GET #show' do
    let(:classroom) { create(:classroom) }

    before do
      allow(controller).to receive(:current_user_classroom).and_return(classroom)
      allow(controller).to receive(:current_school_year).and_return(Date.current.year)
      allow(IeducarApiConfiguration).to receive(:current).and_return(double(to_api: {}))
      allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {}))
    end

    it 'presents the living plan in the read-only form' do
      plan = create(:individualized_educational_plan, year: Date.current.year, characterization: 'Perfil')
      create(:student_enrollment_classroom,
             student_enrollment: create(:student_enrollment, student: plan.student),
             classrooms_grade: create(:classrooms_grade, classroom: classroom))

      get :show, params: { locale: 'pt-BR', id: plan.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:individualized_educational_plan)).to eq(plan)
      expect(assigns(:individualized_educational_plan).characterization).to eq('Perfil')
    end

    it 'does not open an archived plan' do
      plan = create(:individualized_educational_plan, year: Date.current.year)
      create(:student_enrollment_classroom,
             student_enrollment: create(:student_enrollment, student: plan.student),
             classrooms_grade: create(:classrooms_grade, classroom: classroom))
      plan.discard

      get :show, params: { locale: 'pt-BR', id: plan.id }

      expect(response).to redirect_to(individualized_educational_plans_path)
      expect(assigns(:individualized_educational_plan)).to be_nil
    end

    it 'does not open a plan from a classroom the user is not linked to' do
      plan = create(:individualized_educational_plan)

      get :show, params: { locale: 'pt-BR', id: plan.id }

      expect(response).to redirect_to(individualized_educational_plans_path)
      expect(assigns(:individualized_educational_plan)).to be_nil
    end
  end

  describe 'GET #show as pdf' do
    render_views

    before do
      allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))
      allow(controller).to receive(:accessible_plans).and_return(IndividualizedEducationalPlan.kept)
      allow(controller).to receive(:plan_editable?).and_return(true)
      allow(IeducarApiConfiguration).to receive(:current).and_return(double(to_api: {}))
      allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {}))
    end

    it 'renders the plan content and sends the generated pdf' do
      plan = create(:individualized_educational_plan, characterization: 'Perfil impresso')
      allow(ReportGenerator).to receive(:call).and_return(double(body: '%PDF-fake'))

      get :show, params: { locale: 'pt-BR', id: plan.id, format: :pdf }

      expect(response.body).to eq('%PDF-fake')
      expect(response.headers['Content-Type']).to include('application/pdf')
      expect(ReportGenerator).to have_received(:call).with(a_string_including('Perfil impresso'))
    end

    it 'redirects with an alert when the external pdf service fails' do
      plan = create(:individualized_educational_plan)
      allow(ReportGenerator).to receive(:call).and_raise(RestClient::Exceptions::ReadTimeout)

      get :show, params: { locale: 'pt-BR', id: plan.id, format: :pdf }

      expect(response).to redirect_to(individualized_educational_plans_path)
      expect(flash[:alert]).to be_present
    end

    it 'redirects with an alert when the service returns a non-pdf body' do
      plan = create(:individualized_educational_plan)
      allow(ReportGenerator).to receive(:call).and_return(double(body: '<html>erro</html>'))

      get :show, params: { locale: 'pt-BR', id: plan.id, format: :pdf }

      expect(response).to redirect_to(individualized_educational_plans_path)
      expect(flash[:alert]).to be_present
    end

    it 'redirects to the root path when not authorized' do
      plan = create(:individualized_educational_plan)
      allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)

      get :show, params: { locale: 'pt-BR', id: plan.id, format: :pdf }

      expect(response).to redirect_to(root_path)
    end
  end

  describe 'GET #new' do
    it 'shows the profile classroom regent (i-Educar) as the derived teacher' do
      regent = create(:teacher, api_code: '777')
      classroom = create(:classroom, regent_api_code: '777')
      allow(controller).to receive(:current_user_classroom).and_return(classroom)

      get :new, params: { locale: 'pt-BR' }

      expect(assigns(:individualized_educational_plan).teacher_name).to eq(regent.name)
    end

    it 'leaves the teacher blank when the classroom has no regent (no fallback)' do
      classroom = create(:classroom, regent_api_code: nil)
      allow(controller).to receive(:current_user_classroom).and_return(classroom)
      allow(controller).to receive(:current_teacher).and_return(create(:teacher))

      get :new, params: { locale: 'pt-BR' }

      expect(assigns(:individualized_educational_plan).teacher_name).to be_nil
    end

    it 'shows 3 review date fields by default' do
      allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))

      get :new, params: { locale: 'pt-BR' }

      expect(assigns(:individualized_educational_plan).iep_review_dates.size).to eq(3)
    end

    # O require_current_classroom roda em TODAS as actions (não só no index): sem turma
    # no perfil, o new também é barrado antes de montar o formulário.
    it 'redirects to root without a classroom in the profile' do
      allow(controller).to receive(:current_user_classroom).and_return(nil)

      get :new, params: { locale: 'pt-BR' }

      expect(response).to redirect_to(root_path)
    end
  end

  describe 'GET #edit' do
    let(:classroom) { create(:classroom) }

    before do
      allow(controller).to receive(:current_user_classroom).and_return(classroom)
      allow(controller).to receive(:current_school_year).and_return(Date.current.year)
      allow(IeducarApiConfiguration).to receive(:current).and_return(double(to_api: {}))
      allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {}))
    end

    it 'keeps 3 review date fields, completing the persisted ones' do
      plan = create(:individualized_educational_plan, year: Date.current.year)
      create(:iep_review_date, iep: plan, review_date: Date.current)
      create(:student_enrollment_classroom,
             student_enrollment: create(:student_enrollment, student: plan.student),
             classrooms_grade: create(:classrooms_grade, classroom: classroom))

      get :edit, params: { locale: 'pt-BR', id: plan.id }

      review_dates = assigns(:individualized_educational_plan).iep_review_dates
      expect(review_dates.size).to eq(3)
      expect(review_dates.select(&:persisted?).map(&:review_date)).to eq([Date.current])
    end
  end

  describe 'POST #create' do
    before do
      allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))
      # alguns exemplos deste bloco exercitam o fluxo real de update das seções 4/5 (patch :update),
      # que passa por plan_with_components → accessible_plans.
      allow(controller).to receive(:accessible_plans).and_return(IndividualizedEducationalPlan.kept)
      allow(controller).to receive(:plan_editable?).and_return(true)
      # Aluno permitido: a fronteira server-side do create é exercida em teste próprio.
      allow(controller).to receive(:student_permitted_for_creation?).and_return(true)
      allow(controller).to receive(:current_school_year).and_return(Date.current.year)
    end

    let(:valid_params) do
      {
        student_id: create(:student).id,
        elaborated_at: Date.current,
        characterization: 'Perfil do estudante',
        iep_review_dates_attributes: { '0' => { review_date: Date.current + 30 } }
      }
    end

    it 'blocks creating when the elaboration date is not a school calendar day' do
      allow(IndividualizedEducationalPlanElaborationDayCheck).to receive(:error_for)
        .and_return(I18n.t('errors.messages.is_not_between_steps'))

      expect do
        post :create, params: {
          locale: 'pt-BR', version_name: 'Versão 1', individualized_educational_plan: valid_params
        }
      end.not_to change(IndividualizedEducationalPlan, :count)

      expect(response).to render_template(:new)
      expect(assigns(:individualized_educational_plan).errors[:elaborated_at])
        .to include(I18n.t('errors.messages.is_not_between_steps'))
    end

    # Sem stub do day check: quem barra aqui é o model.
    it 'blocks creating with a future elaboration date' do
      expect do
        post :create, params: {
          locale: 'pt-BR', version_name: 'Versão 1',
          individualized_educational_plan: valid_params.merge(elaborated_at: Date.current + 1)
        }
      end.not_to change(IndividualizedEducationalPlan, :count)

      expect(response).to render_template(:new)
      expect(assigns(:individualized_educational_plan).errors[:elaborated_at])
        .to include(I18n.t('errors.messages.not_in_future'))
    end

    # Pundit antes dos guards de negócio: professor tem que levar 403, não o redirect de "já existe".
    it 'runs the policy before the existing-plan redirect' do
      student = create(:student)
      create(:individualized_educational_plan, student: student, year: Date.current.year)
      allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)

      post :create, params: {
        locale: 'pt-BR', version_name: 'Versão 1',
        individualized_educational_plan: { student_id: student.id }
      }

      expect(response).to redirect_to(root_path)
    end

    it 'routes to the existing plan instead of creating a duplicate' do
      student = create(:student)
      existing = create(:individualized_educational_plan, student: student, year: Date.current.year)

      expect do
        post :create, params: {
          locale: 'pt-BR', version_name: 'Versão 1',
          individualized_educational_plan: { student_id: student.id }
        }
      end.not_to change(IndividualizedEducationalPlan, :count)

      expect(response).to redirect_to(edit_individualized_educational_plan_path(existing))
      expect(flash[:notice]).to eq(I18n.t('individualized_educational_plans.flash.already_exists_editing'))
    end

    # 'false' como string, igual ao submit do select: prova o permit + cast do boolean tri-state.
    it 'persists the medication answer, notes and family environment fields' do
      post :create, params: {
        locale: 'pt-BR', version_name: 'Versão 1',
        individualized_educational_plan: valid_params.merge(
          uses_medication: 'false', medication_notes: 'Apos o almoco',
          family_environment_characteristics: 'Rotina estruturada'
        )
      }

      plan = assigns(:individualized_educational_plan).reload
      expect(plan.uses_medication).to eq(false)
      expect(plan.medication_notes).to eq('Apos o almoco')
      expect(plan.family_environment_characteristics).to eq('Rotina estruturada')
    end

    it 'persists several medications in the submitted order, skipping blank rows' do
      post :create, params: {
        locale: 'pt-BR', version_name: 'Versão 1',
        individualized_educational_plan: valid_params.merge(
          uses_medication: 'true',
          iep_medications_attributes: {
            '0' => { name: 'Metilfenidato', dosage: '10 mg', schedule: '07h30' },
            '1' => { name: '', dosage: '', schedule: '' },
            '2' => { name: 'Risperidona', dosage: '1 mg', schedule: '20h00' }
          }
        )
      }

      medications = assigns(:individualized_educational_plan).reload.iep_medications
      expect(medications.map { |medication| [medication.name, medication.dosage, medication.schedule] })
        .to eq([['Metilfenidato', '10 mg', '07h30'], ['Risperidona', '1 mg', '20h00']])
    end

    it 'rejects a "yes" medication answer without a named medication' do
      expect do
        post :create, params: {
          locale: 'pt-BR', version_name: 'Versão 1',
          individualized_educational_plan: valid_params.merge(
            uses_medication: 'true',
            iep_medications_attributes: { '0' => { name: '', dosage: '5 mg', schedule: '' } }
          )
        }
      end.not_to change(IndividualizedEducationalPlan, :count)

      expect(response).to render_template(:new)
    end

    # '' (select em branco) tem que virar nil — o "não respondido" do tri-state. Um default na
    # coluna, ou um cast diferente, transformaria silêncio em resposta.
    it 'keeps an unanswered medication select as nil' do
      post :create, params: {
        locale: 'pt-BR', version_name: 'Versão 1',
        individualized_educational_plan: valid_params.merge(uses_medication: '')
      }

      expect(assigns(:individualized_educational_plan).reload.uses_medication).to be_nil
    end

    it 'casts a "true" medication answer to the boolean true' do
      post :create, params: {
        locale: 'pt-BR', version_name: 'Versão 1',
        individualized_educational_plan: valid_params.merge(
          uses_medication: 'true', iep_medications_attributes: { '0' => { name: 'Metilfenidato' } }
        )
      }

      expect(assigns(:individualized_educational_plan).reload.uses_medication).to eq(true)
    end

    # O par completo da feature: o arquivado não pode nem ser reaberto no lugar do novo, nem
    # impedir a criação. É aqui que a validação e o índice parcial se encontram com a tela.
    it 'creates a new plan for a student whose previous plan was archived' do
      student = create(:student)
      archived = create(:individualized_educational_plan, student: student, year: Date.current.year)
      archived.discard

      expect do
        post :create, params: {
          locale: 'pt-BR', version_name: 'Versão 1',
          individualized_educational_plan: valid_params.merge(student_id: student.id)
        }
      end.to change(IndividualizedEducationalPlan, :count).by(1)

      expect(response).not_to redirect_to(edit_individualized_educational_plan_path(archived))
      expect(archived.reload).to be_discarded
    end

    it 'creates the plan and publishes the first version' do
      expect do
        post :create, params: {
          locale: 'pt-BR', version_name: 'Versão 1', individualized_educational_plan: valid_params
        }
      end.to change(IndividualizedEducationalPlan, :count).by(1)

      expect(response).to redirect_to(individualized_educational_plans_path)
      expect(IndividualizedEducationalPlan.last.active_version.name).to eq('Versão 1')
    end

    it 'persists the review dates' do
      post :create, params: {
        locale: 'pt-BR', version_name: 'Versão 1', individualized_educational_plan: valid_params
      }

      expect(IndividualizedEducationalPlan.last.iep_review_dates.map(&:review_date)).to eq([Date.current + 30])
    end

    it 'ignores a year sent by the client and uses the current school year' do
      post :create, params: {
        locale: 'pt-BR', version_name: 'Versão 1',
        individualized_educational_plan: valid_params.merge(year: 2000)
      }

      expect(IndividualizedEducationalPlan.last.year).to eq(Date.current.year)
    end

    it 'rejects a student not enrolled in the profile classroom on the elaboration date' do
      allow(controller).to receive(:student_permitted_for_creation?).and_call_original

      expect do
        post :create, params: {
          locale: 'pt-BR', version_name: 'Versão 1', individualized_educational_plan: valid_params
        }
      end.not_to change(IndividualizedEducationalPlan, :count)

      expect(response).to render_template(:new)
      expect(assigns(:individualized_educational_plan).errors[:student_id])
        .to include(I18n.t('individualized_educational_plans.create.student_not_permitted'))
    end

    it 'assigns the multi-select options' do
      option = create(:iep_option)

      post :create, params: {
        locale: 'pt-BR', version_name: 'Versão 1',
        individualized_educational_plan: valid_params.merge(communication_profile_option_ids: [option.id])
      }

      expect(IndividualizedEducationalPlan.last.communication_profile_option_ids).to eq([option.id])
    end

    it 'assigns the multi-select options submitted as a comma-separated string (select2 format)' do
      options = create_list(:iep_option, 2)

      post :create, params: {
        locale: 'pt-BR', version_name: 'Versão 1',
        individualized_educational_plan: valid_params.merge(
          communication_profile_option_ids: options.map(&:id).join(',')
        )
      }

      expect(IndividualizedEducationalPlan.last.communication_profile_option_ids).to match_array(options.map(&:id))
    end

    it 'does not create an invalid plan (missing required fields)' do
      expect do
        post :create, params: {
          locale: 'pt-BR', version_name: 'Versão 1',
          individualized_educational_plan: valid_params.merge(student_id: nil)
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
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
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
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
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
    before do
      allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))
      allow(controller).to receive(:accessible_plans).and_return(IndividualizedEducationalPlan.kept)
      allow(controller).to receive(:plan_editable?).and_return(true)
    end

    it 'removes a saved medication marked for destruction' do
      plan = create(:individualized_educational_plan, uses_medication: true,
                                                      iep_medications_attributes: [{ name: 'Metilfenidato' },
                                                                                   { name: 'Risperidona' }])
      kept, removed = plan.iep_medications

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: {
          iep_medications_attributes: {
            '0' => { id: kept.id, name: 'Metilfenidato' },
            '1' => { id: removed.id, name: 'Risperidona', _destroy: '1' }
          }
        }
      }

      expect(plan.reload.iep_medications).to eq([kept])
    end

    it 'discards the medications when the answer changes to "no"' do
      plan = create(:individualized_educational_plan, uses_medication: true,
                                                      iep_medications_attributes: [{ name: 'Metilfenidato' }])
      medication = plan.iep_medications.first

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: {
          uses_medication: 'false',
          iep_medications_attributes: { '0' => { id: medication.id, name: medication.name } }
        }
      }

      expect(plan.reload.uses_medication).to eq(false)
      expect(plan.iep_medications).to be_empty
    end

    it 'renders edit with a friendly error when removing a review that has section data' do
      plan = create(:individualized_educational_plan)
      review_date = create(:iep_review_date, iep: plan)
      create(:iep_curricular_planning, iep: plan, iep_review_date: review_date, long_term_goal: 'Meta')

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
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
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
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
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
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

    it 'clears a section line and removes its review in the same submit (regression: prune ran too late to allow it)' do
      plan = create(:individualized_educational_plan)
      review_date = create(:iep_review_date, iep: plan)
      planning = create(:iep_curricular_planning, iep: plan, iep_review_date: review_date, long_term_goal: 'Meta')

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: {
          iep_curricular_plannings_attributes: { '0' => {
            id: planning.id, long_term_goal: '', stage_objectives: '', skills_to_develop: '', methodologies: '',
            instructional_accommodation_option_ids: '', environmental_accommodation_option_ids: '',
            assessment_accommodation_option_ids: ''
          } },
          iep_review_dates_attributes: { '0' => { id: review_date.id, _destroy: '1' } }
        }
      }

      expect(response).to redirect_to(individualized_educational_plans_path)
      expect(IepCurricularPlanning.exists?(planning.id)).to eq(false)
      expect(IepReviewDate.exists?(review_date.id)).to eq(false)
    end

    it 'updates the plan and redirects to the index' do
      plan = create(:individualized_educational_plan)

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: { characterization: 'Atualizado' }
      }

      expect(plan.reload.characterization).to eq('Atualizado')
      expect(response).to redirect_to(individualized_educational_plans_path)
    end

    it 'does not allow the student to be changed on update' do
      plan = create(:individualized_educational_plan)
      new_student = create(:student)

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: { student_id: new_student.id, characterization: 'Tentativa de troca' }
      }

      expect(plan.reload.student_id).not_to eq(new_student.id)
      expect(plan.reload.characterization).to eq('Tentativa de troca')
    end

    it 'assigns section 4 accommodations submitted as a comma-separated string (select2 nested)' do
      plan = create(:individualized_educational_plan)
      review_date = create(:iep_review_date, iep: plan)
      discipline = create(:discipline)
      acc_a = create(:iep_option, :instructional_accommodation)
      acc_b = create(:iep_option, :instructional_accommodation)

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: {
          iep_curricular_plannings_attributes: { '0' => {
            iep_review_date_id: review_date.id, discipline_id: discipline.id, long_term_goal: 'Meta',
            instructional_accommodation_option_ids: [acc_a.id, acc_b.id].join(',')
          } }
        }
      }

      planning = plan.reload.iep_curricular_plannings.first
      expect(planning.instructional_accommodation_option_ids).to match_array([acc_a.id, acc_b.id])
    end

  end

  describe 'finalization (save + publish in the same submit)' do
    before do
      allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))
      allow(controller).to receive(:accessible_plans).and_return(IndividualizedEducationalPlan.kept)
      allow(controller).to receive(:plan_editable?).and_return(true)
      allow(controller).to receive(:student_permitted_for_creation?).and_return(true)
      allow(controller).to receive(:current_school_year).and_return(Date.current.year)
    end

    it 'publishes an active version when updating with a version name' do
      plan = create(:individualized_educational_plan)

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: { characterization: 'Atualizado' }
      }

      expect(response).to redirect_to(individualized_educational_plans_path)
      expect(plan.reload.characterization).to eq('Atualizado')
      version = plan.active_version
      expect(version.name).to eq('Versão 1')
      expect(version.published_by).to eq(user)
      expect(version.content['characterization']['characterization']).to eq('Atualizado')
      expect(plan.finalized?).to eq(true)
    end

    # Escola que recebeu o aluno não pode ser travada por um elaborated_at readonly (de outra escola).
    it 'does not revalidate the school-calendar day on update when the elaboration date is unchanged' do
      plan = create(:individualized_educational_plan)
      expect(IndividualizedEducationalPlanElaborationDayCheck).not_to receive(:error_for)

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: { characterization: 'Atualizado' }
      }

      expect(plan.reload.active_version.name).to eq('Versão 1')
    end

    it 'publishes the first version right on creation' do
      student = create(:student)

      post :create, params: {
        locale: 'pt-BR', version_name: 'Primeira versão',
        individualized_educational_plan: { student_id: student.id, elaborated_at: Date.current }
      }

      plan = IndividualizedEducationalPlan.last
      expect(plan.finalized?).to eq(true)
      expect(plan.active_version.name).to eq('Primeira versão')
    end

    it 'does not save without a version name' do
      plan = create(:individualized_educational_plan, characterization: 'Original')

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, individualized_educational_plan: { characterization: 'Alterado' }
      }

      expect(response).to render_template(:edit)
      expect(plan.reload.characterization).to eq('Original')
      expect(plan.iep_versions.count).to eq(0)
      expect(assigns(:individualized_educational_plan).errors[:base])
        .to include(I18n.t('individualized_educational_plans.finalize.version_name_required'))
    end

    it 'publishes nothing when the plan itself is invalid' do
      plan = create(:individualized_educational_plan)

      # elaborated_at é obrigatório e editável; zerá-lo invalida o plano (o student_id
      # não é editável no update, então não serviria para invalidar).
      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: { elaborated_at: nil }
      }

      expect(response).to render_template(:edit)
      expect(plan.reload.iep_versions.count).to eq(0)
    end

    it 'rolls back the plan save when the finalize authorization is denied' do
      plan = create(:individualized_educational_plan, characterization: 'Original')
      allow(controller).to receive(:authorize)
        .with(kind_of(IndividualizedEducationalPlan), :finalize?).and_raise(Pundit::NotAuthorizedError)

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: { characterization: 'Alterado' }
      }

      expect(response).to redirect_to(root_path)
      expect(plan.reload.characterization).to eq('Original')
      expect(plan.iep_versions.count).to eq(0)
    end

    it 'shows a friendly error instead of a generic failure on a concurrent finalize collision' do
      plan = create(:individualized_educational_plan)
      allow(IndividualizedEducationalPlanPublisher).to receive(:publish!)
        .and_raise(ActiveRecord::RecordNotUnique.new('duplicate active version'))

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
        individualized_educational_plan: { characterization: 'X' }
      }

      expect(response).to render_template(:edit)
      expect(assigns(:individualized_educational_plan).errors[:base])
        .to include(I18n.t('individualized_educational_plans.finalize.already_published'))
      expect(plan.reload.iep_versions.count).to eq(0)
    end
  end

  describe 'draft save (create/update with draft, answered in JSON)' do
    let(:student) { create(:student) }
    let(:draft_params) { { student_id: student.id, elaborated_at: Date.current } }
    let(:body) { JSON.parse(response.body) }

    before do
      allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))
      allow(controller).to receive(:accessible_plans).and_return(IndividualizedEducationalPlan.kept)
      allow(controller).to receive(:plan_editable?).and_return(true)
      allow(controller).to receive(:student_permitted_for_creation?).and_return(true)
      allow(controller).to receive(:current_school_year).and_return(Date.current.year)
      allow(IeducarApiConfiguration).to receive(:current).and_return(double(to_api: {}))
      allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {}))
    end

    def create_draft(attributes = draft_params)
      post :create, params: { locale: 'pt-BR', draft: '1', individualized_educational_plan: attributes }
    end

    def update_draft(plan, attributes)
      patch :update, params: {
        locale: 'pt-BR', id: plan.id, draft: '1', individualized_educational_plan: attributes
      }
    end

    describe 'POST #create' do
      it 'creates the plan in progress, without publishing a version' do
        create_draft(draft_params.merge(iep_review_dates_attributes: { '0' => { review_date: Date.current } }))

        plan = IndividualizedEducationalPlan.last
        expect(response).to have_http_status(:ok)
        expect(plan.student).to eq(student)
        expect(plan.iep_review_dates.count).to eq(1)
        expect(plan.iep_versions.count).to eq(0)
        expect(plan.finalized?).to eq(false)
        expect(body).to include(
          'id' => plan.id,
          'update_url' => individualized_educational_plan_path(plan),
          'edit_url' => edit_individualized_educational_plan_path(plan)
        )
      end

      it 'points to the existing plan instead of creating another for the same student and year' do
        existing = create(:individualized_educational_plan, student: student, year: Date.current.year)

        expect { create_draft }.not_to change(IndividualizedEducationalPlan, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(body['existing_plan_url']).to eq(edit_individualized_educational_plan_path(existing))
      end

      it 'refuses a student that is not enrolled on the elaboration date' do
        allow(controller).to receive(:student_permitted_for_creation?).and_return(false)

        expect { create_draft }.not_to change(IndividualizedEducationalPlan, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(body['errors']).to include(I18n.t('individualized_educational_plans.create.student_not_permitted'))
      end

      # Sem versão não há autoria: o rascunho de quem não cursa mais a turma não poderia ser reaberto.
      it 'does not save a draft for a student that no longer attends the classroom' do
        allow(controller).to receive(:plan_editable?).and_return(false)

        expect { create_draft }.not_to change(IndividualizedEducationalPlan, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(body['draft_unavailable']).to eq(true)
      end

      it 'blocks an elaboration date that is not a school calendar day' do
        allow(IndividualizedEducationalPlanElaborationDayCheck).to receive(:error_for)
          .and_return(I18n.t('errors.messages.is_not_between_steps'))

        expect { create_draft }.not_to change(IndividualizedEducationalPlan, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(body['errors'].join).to include(I18n.t('errors.messages.is_not_between_steps'))
      end

      it 'answers a conflict message when the same plan is created twice at the same time' do
        allow_any_instance_of(IndividualizedEducationalPlan).to receive(:save_draft)
          .and_raise(ActiveRecord::RecordNotUnique.new('duplicate student and year'))

        create_draft

        expect(response).to have_http_status(:unprocessable_entity)
        expect(body['errors']).to include(I18n.t('individualized_educational_plans.draft.conflict'))
      end

      # Sem stub de acesso: a regra sai das enturmações reais do aluno na turma do perfil.
      context 'with the real enrollments of the student' do
        let(:classroom) { create(:classroom, year: Date.current.year) }
        let(:elaborated_at) { Date.new(Date.current.year, 5, 15) }

        around { |example| Timecop.freeze(Time.zone.local(Date.current.year, 6, 15, 12)) { example.run } }

        before do
          allow(controller).to receive(:current_user_classroom).and_return(classroom)
          allow(controller).to receive(:accessible_plans).and_call_original
          allow(controller).to receive(:plan_editable?).and_call_original
          allow(controller).to receive(:student_permitted_for_creation?).and_call_original
          allow(IndividualizedEducationalPlanElaborationDayCheck).to receive(:error_for).and_return(nil)
        end

        it 'saves the draft of a student attending the classroom' do
          enroll(student, classroom)

          expect { create_draft(draft_params.merge(elaborated_at: elaborated_at)) }
            .to change(IndividualizedEducationalPlan, :count).by(1)

          expect(response).to have_http_status(:ok)
        end

        it 'refuses the draft of a student enrolled on the elaboration date but transferred since' do
          enrollment = create(:student_enrollment, student: student, status: StudentEnrollmentStatus::TRANSFERRED)
          create(:student_enrollment_classroom,
                 student_enrollment: enrollment, classrooms_grade: create(:classrooms_grade, classroom: classroom),
                 joined_at: "#{Date.current.year}-02-01", left_at: "#{Date.current.year}-06-01")

          expect { create_draft(draft_params.merge(elaborated_at: elaborated_at)) }
            .not_to change(IndividualizedEducationalPlan, :count)

          expect(body['draft_unavailable']).to eq(true)
        end
      end
    end

    # O formulário novo que volta com erro para um aluno sem rascunho abre com o salvamento
    # automático desligado.
    it 'flags the draft as unavailable when the new form is rendered again for such a student' do
      allow(controller).to receive(:plan_editable?).and_return(false)

      post :create, params: { locale: 'pt-BR', individualized_educational_plan: draft_params }

      expect(response).to render_template(:new)
      expect(assigns(:draft_unavailable)).to eq(true)
    end

    describe 'PATCH #update' do
      let(:plan) { create(:individualized_educational_plan, student: student, characterization: 'Original') }

      it 'saves without publishing a version' do
        update_draft(plan, characterization: 'Alterado')

        expect(response).to have_http_status(:ok)
        expect(plan.reload.characterization).to eq('Alterado')
        expect(plan.iep_versions.count).to eq(0)
      end

      it 'moves a finalized plan back to in progress, keeping the published version' do
        patch :update, params: {
          locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
          individualized_educational_plan: { characterization: 'Publicado' }
        }
        expect(plan.reload.finalized?).to eq(true)

        update_draft(plan, characterization: 'Alterado depois')

        expect(plan.reload.finalized?).to eq(false)
        expect(plan.iep_versions.count).to eq(1)
        expect(plan.active_version.content['characterization']['characterization']).to eq('Publicado')
      end

      it 'does not duplicate the nested records sent back with their ids' do
        review = create(:iep_review_date, iep: plan, review_date: Date.current)

        update_draft(plan, iep_review_dates_attributes: {
                       '0' => { id: review.id, review_date: Date.current },
                       '1' => { review_date: '' }
                     })

        expect(plan.reload.iep_review_dates).to contain_exactly(review)
      end

      it 'returns the validation errors and saves nothing' do
        update_draft(plan, characterization: 'Alterado', elaborated_at: nil)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(body['errors']).to be_present
        expect(plan.reload.characterization).to eq('Original')
      end

      # Outro usuário removeu a linha depois que esta tela foi carregada.
      it 'answers a conflict, not a missing plan, when a line sent back was removed meanwhile' do
        review = create(:iep_review_date, iep: plan, review_date: Date.current)
        line = create(:iep_curricular_planning, iep: plan, iep_review_date: review, long_term_goal: 'Meta')
        line.destroy

        update_draft(plan, characterization: 'Alterado', iep_curricular_plannings_attributes: {
                       '0' => { id: line.id, long_term_goal: 'Meta revisada' }
                     })

        expect(response).to have_http_status(:conflict)
        expect(body['errors']).to include(I18n.t('individualized_educational_plans.draft.stale_record'))
        expect(plan.reload.characterization).to eq('Original')
      end

      it 'answers 403 in JSON, without redirecting, when the plan is read only' do
        allow(controller).to receive(:plan_editable?).and_return(false)

        update_draft(plan, characterization: 'Alterado')

        expect(response).to have_http_status(:forbidden)
        expect(body['errors']).to include(I18n.t('individualized_educational_plans.flash.read_only_transferred'))
        expect(plan.reload.characterization).to eq('Original')
      end

      it 'answers 404 in JSON, without redirecting, for a plan out of reach' do
        allow(controller).to receive(:accessible_plans).and_return(IndividualizedEducationalPlan.none)

        update_draft(plan, characterization: 'Alterado')

        expect(response).to have_http_status(:not_found)
        expect(body['errors']).to include(I18n.t('individualized_educational_plans.flash.not_found'))
      end

      context 'rendering the form' do
        render_views

        # É do formulário devolvido que a tela tira os ids dos filhos e as revisões das seções 4/5.
        it 'returns the form with the saved review date available in sections 4 and 5' do
          update_draft(plan, iep_review_dates_attributes: { '0' => { review_date: Date.current } })

          review = plan.reload.iep_review_dates.first
          form = Nokogiri::HTML.fragment(body['form_html'])
          expect(form.at_css("#iep-review-dates input[name$='[id]'][value='#{review.id}']")).to be_present
          expect(form.at_css("#pei-step-4 .iep-review-buttons button[data-review-id='#{review.id}']")).to be_present
          expect(form.at_css("#pei-step-5 .iep-review-buttons button[data-review-id='#{review.id}']")).to be_present
        end
      end
    end
  end

  # O acesso ao PEI passa a derivar do grafo de matrícula (o PEI segue o aluno nas
  # transferências), não do classroom_id armazenado. Visível = qualquer enturmação
  # (aberta/fechada); editável = só enturmação ABERTA na turma do usuário.
  describe 'access derived from enrollment and authorship (student transfers)' do
    let(:classroom_a) { create(:classroom, year: Date.current.year) }
    let(:classroom_b) { create(:classroom, year: Date.current.year) }

    before do
      allow(controller).to receive(:current_user_classroom).and_return(classroom_a)
      allow(controller).to receive(:current_school_year).and_return(Date.current.year)
      allow(IeducarApiConfiguration).to receive(:current).and_return(double(to_api: {}))
      allow(IeducarApi::Students).to receive(:new).and_return(double(fetch_by_id: {}))
    end

    # Enturma o aluno numa turma. left_at '' = aberta (cursando); data passada = saiu da turma.
    # status: matrícula (studying = cursando; transferred/abandono/etc. = não cursando).
    def enroll(student, classroom, left_at: '', status: StudentEnrollmentStatus::STUDYING)
      cg = create(:classrooms_grade, classroom: classroom)
      se = create(:student_enrollment, student: student, status: status)
      create(:student_enrollment_classroom, student_enrollment: se, classrooms_grade: cg, left_at: left_at)
    end

    def plan_for(student)
      create(:individualized_educational_plan, student: student, year: Date.current.year)
    end

    # Registra que `classroom` publicou uma versão do plano (autoria — o que dá visibilidade
    # independentemente da matrícula, imune a transferência retroativa).
    def author_version(plan, classroom, published_at: Time.current)
      create(:iep_version, iep: plan, classroom_id: classroom.id, published_at: published_at, active: true,
                           content: { 'identification' => { 'student_name' => plan.student.name } })
    end

    it 'includes plans the classroom is currently teaching or has authored' do
      # cursando a turma do perfil → visível (continuidade), mesmo sem ter publicado nada
      attending = create(:student)
      enroll(attending, classroom_a)
      attending_plan = plan_for(attending)

      # não cursa mais, mas a turma do perfil publicou uma versão → visível (autoria)
      authored = create(:student)
      authored_plan = plan_for(authored)
      author_version(authored_plan, classroom_a)

      # só passou pela turma do perfil (enturmação fechada) sem publicar nada → NÃO visível
      passed = create(:student)
      enroll(passed, classroom_a, left_at: 1.month.ago.to_date.to_s)
      plan_for(passed)

      accessible = controller.send(:accessible_plans)

      # contain_exactly já garante que o plano de quem só passou (passed) fica de fora
      expect(accessible).to contain_exactly(attending_plan, authored_plan)
    end

    it 'excludes a plan the classroom only saw the student pass through (never authored)' do
      student = create(:student)
      enroll(student, classroom_a, left_at: 2.months.ago.to_date.to_s) # passou pela turma e saiu
      plan = plan_for(student)
      author_version(plan, classroom_b) # o plano foi lançado por OUTRA turma

      expect(controller.send(:accessible_plans)).not_to include(plan)
    end

    it 'is editable only when the student has an OPEN enrollment in the profile classroom' do
      active = create(:student)
      enroll(active, classroom_a)
      active_plan = plan_for(active)

      transferred = create(:student)
      enroll(transferred, classroom_a, left_at: 1.month.ago.to_date.to_s)
      transferred_plan = plan_for(transferred)

      expect(controller.send(:plan_editable?, active_plan)).to eq(true)
      expect(controller.send(:plan_editable?, transferred_plan)).to eq(false)
    end

    it 'is not editable when the enrollment status is not attending, even with an open placement' do
      student = create(:student)
      enroll(student, classroom_a, status: StudentEnrollmentStatus::TRANSFERRED) # enturmação aberta, mas status transferido
      plan = plan_for(student)

      expect(controller.send(:plan_editable?, plan)).to eq(false)
    end

    it 'renders edit for an active student and redirects an author who no longer teaches to the read-only view' do
      active = create(:student)
      enroll(active, classroom_a)
      active_plan = plan_for(active)

      # a turma do perfil publicou (autora), mas o aluno não cursa mais ela
      transferred = create(:student)
      transferred_plan = plan_for(transferred)
      author_version(transferred_plan, classroom_a)

      get :edit, params: { locale: 'pt-BR', id: active_plan.id }
      expect(response).to have_http_status(:ok)

      # Não cursa mais → não edita: cai na visualização (que leva à versão congelada em leitura).
      get :edit, params: { locale: 'pt-BR', id: transferred_plan.id }
      expect(response).to redirect_to(individualized_educational_plan_path(transferred_plan))
    end

    it 'blocks updating the plan of a student the classroom no longer teaches (read-only)' do
      transferred = create(:student)
      plan = plan_for(transferred)
      author_version(plan, classroom_a) # visível por autoria; aluno não cursa mais → leitura

      expect do
        patch :update, params: {
          locale: 'pt-BR', id: plan.id, version_name: 'Versão 1',
          individualized_educational_plan: { characterization: 'Invadido' }
        }
      end.not_to change { plan.reload.iep_versions.count }

      expect(response).to redirect_to(individualized_educational_plan_path(plan))
      expect(flash[:alert]).to eq(I18n.t('individualized_educational_plans.flash.read_only_transferred'))
    end

    it 'redirects show to the frozen version for an author who no longer teaches (freeze)' do
      transferred = create(:student)
      plan = plan_for(transferred)
      frozen = author_version(plan, classroom_a, published_at: 2.months.ago)

      get :show, params: { locale: 'pt-BR', id: plan.id }

      expect(response).to redirect_to(individualized_educational_plan_version_path(plan, frozen))
    end

    # O congelamento também vale no PDF: sem isto, imprimir levaria ao plano vivo (com o conteúdo
    # que a turma nova lançou depois).
    it 'redirects show.pdf to the frozen version pdf' do
      transferred = create(:student)
      plan = plan_for(transferred)
      frozen = author_version(plan, classroom_a, published_at: 2.months.ago)

      get :show, params: { locale: 'pt-BR', id: plan.id, format: :pdf }

      expect(response).to redirect_to(individualized_educational_plan_version_path(plan, frozen, format: :pdf))
    end

    # Aluno cursando duas turmas acessíveis ao mesmo tempo. O contexto
    # exibido/carimbado é a turma pela qual o usuário está acessando (a do perfil), não uma
    # qualquer — mesmo que ela ainda não tenha publicado nenhuma versão.
    it 'uses the viewing classroom as the context, even one that has not authored yet' do
      student = create(:student)
      enroll(student, classroom_a) # turma que já poderia ter criado o PEI
      enroll(student, classroom_b) # turma pela qual o usuário está acessando agora
      plan = plan_for(student)
      allow(controller).to receive(:accessible_classrooms).and_return([classroom_a, classroom_b])
      allow(controller).to receive(:current_user_classroom).and_return(classroom_b)

      expect(controller.send(:current_classroom_for, plan)).to eq(classroom_b)
    end
  end
end
