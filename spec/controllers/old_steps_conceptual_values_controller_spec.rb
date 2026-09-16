require 'spec_helper'

RSpec.describe OldStepsConceptualValuesController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user, :with_user_role_administrator) }
  let(:user_role) { user.user_roles.first }
  let(:unity) { user_role.unity }
  let(:school_calendar) { create(:school_calendar, unity: unity) }
  let(:classroom) do
    create(:classroom, :with_classroom_trimester_steps, unity: unity, school_calendar: school_calendar)
  end
  # Mesmo SchoolCalendar da turma acima, como em produção: a etapa fica
  # inalcançável pelo filtro de school_calendar_classroom.classroom_steps,
  # e não porque o calendário é outro
  let(:other_classroom) do
    create(:classroom, :with_classroom_trimester_steps, unity: unity, school_calendar: school_calendar)
  end
  let(:steps) { classroom.calendar.classroom_steps }
  let(:other_classroom_step) { other_classroom.calendar.classroom_steps.first }
  let(:student) { create(:student) }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  before do
    sign_in(user)
    request.env['REQUEST_PATH'] = ''
  end

  describe 'GET #index' do
    context 'when the step belongs to the classroom calendar' do
      it 'returns the previous steps of the classroom' do
        get :index, params: {
          locale: 'pt-BR',
          classroom_id: classroom.id,
          student_id: student.id,
          step_id: steps[1].id
        }, format: :json

        expect(response).to have_http_status(:ok)

        # O AMS sobrescreve o render json: e embrulha arrays usando controller_name
        # como root key, formato consumido por views/conceptual_exams/form.js
        parsed = JSON.parse(response.body)['old_steps_conceptual_values']
        expect(parsed.size).to eq(1)
        expect(parsed.first['description']).to eq(steps[0].to_s)
        expect(parsed.first['values']).to eq({})
      end
    end

    context 'when the step belongs to another classroom calendar' do
      # Cenário registrado em produção: a etapa vinha da lista montada para a
      # turma corrente da sessão, não para a turma do lançamento. Sem o guard no
      # fetcher a action estoura e o rescue_from Exception devolve 302 para a raiz.
      it 'returns an empty list instead of redirecting to root' do
        get :index, params: {
          locale: 'pt-BR',
          classroom_id: classroom.id,
          student_id: student.id,
          step_id: other_classroom_step.id
        }, format: :json

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq('old_steps_conceptual_values' => [])
      end
    end

    context 'when the classroom has no school calendar' do
      # StepsFetcher#step_by_id retorna nil antes de consultar as etapas quando a
      # turma não tem calendário no ano — estado rotineiro em início de ano letivo
      let(:classroom_without_calendar) { create(:classroom, unity: unity) }

      it 'returns an empty list instead of redirecting to root' do
        get :index, params: {
          locale: 'pt-BR',
          classroom_id: classroom_without_calendar.id,
          student_id: student.id,
          step_id: steps[0].id
        }, format: :json

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq('old_steps_conceptual_values' => [])
      end
    end
  end

  describe 'GET #index authorization' do
    let(:discipline) { create(:discipline) }
    let(:owner_teacher) { create(:teacher) }
    let(:previous_step) { steps[0] }
    let(:current_step) { steps[1] }
    let(:released_value) { '8.0' }

    let!(:owner_link) do
      create(
        :teacher_discipline_classroom,
        classroom: classroom,
        teacher: owner_teacher,
        discipline: discipline
      )
    end

    let!(:conceptual_exam) do
      exam = build(
        :conceptual_exam,
        :with_student_enrollment_classroom,
        classroom: classroom,
        student: student,
        teacher_id: owner_teacher.id,
        step_number: previous_step.step_number,
        step_id: previous_step.id
      )
      exam.conceptual_exam_values.build(discipline: discipline, value: 8)
      exam.save!
      exam
    end

    def sign_in_as(other_user)
      sign_out(user)
      sign_in(other_user)
    end

    def allow_conceptual_exams(role)
      create(
        :role_permission,
        role: role,
        feature: 'conceptual_exams',
        permission: Permissions::READ
      )
    end

    def teacher_user(teacher)
      create(:user, :with_user_role_teacher, admin: false, teacher: teacher).tap do |created_user|
        allow_conceptual_exams(created_user.current_user_role.role)
      end
    end

    def request_old_steps
      get :index, params: {
        locale: 'pt-BR',
        classroom_id: classroom.id,
        student_id: student.id,
        step_id: current_step.id
      }, format: :json
    end

    context 'when the current teacher is linked to the classroom' do
      it 'returns the conceptual values of the previous steps' do
        sign_in_as(teacher_user(owner_teacher))

        request_old_steps

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['old_steps_conceptual_values'].first['values']).to eq(
          discipline.id.to_s => released_value
        )
      end
    end

    context 'when the current teacher has no link to the classroom' do
      it 'denies the request instead of returning the conceptual values' do
        sign_in_as(teacher_user(create(:teacher)))

        request_old_steps

        expect(response).to redirect_to(root_path)
      end
    end

    context 'when the link to the classroom was discarded' do
      # Vínculo descartado tira a turma das telas do professor; a leitura dos
      # conceitos das etapas anteriores acompanha
      it 'denies the request' do
        sign_in_as(teacher_user(owner_teacher))
        owner_link.discard

        request_old_steps

        expect(response).to redirect_to(root_path)
      end
    end

    context 'when the user has a teacher role without a teacher record' do
      it 'denies the request' do
        user_without_teacher = create(:user, :with_user_role_teacher, admin: false)
        allow_conceptual_exams(user_without_teacher.current_user_role.role)

        sign_in_as(user_without_teacher)

        request_old_steps

        expect(response).to redirect_to(root_path)
      end
    end

    context 'when the role has no permission on conceptual exams' do
      it 'denies the request even for a teacher linked to the classroom' do
        sign_in_as(create(:user, :with_user_role_teacher, admin: false, teacher: owner_teacher))

        request_old_steps

        expect(response).to redirect_to(root_path)
      end
    end

    context 'when the user is an employee' do
      it 'returns the conceptual values of a classroom outside the session' do
        employee = create(:user, admin: false)
        employee_role = create(:user_role, role: create(:role, access_level: AccessLevel::EMPLOYEE))
        employee.user_roles << employee_role
        employee.current_user_role = employee_role
        employee.save!
        allow_conceptual_exams(employee_role.role)

        sign_in_as(employee)

        request_old_steps

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['old_steps_conceptual_values'].first['values']).to eq(
          discipline.id.to_s => released_value
        )
      end
    end
  end
end
