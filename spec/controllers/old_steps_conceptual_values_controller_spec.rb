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
end
