require 'spec_helper'

RSpec.describe ConceptualExamsController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user, :with_user_role_administrator) }
  let(:user_role) { user.user_roles.first }
  let(:unity) { user_role.unity }
  let(:current_teacher) { create(:teacher) }
  let(:discipline) { create(:discipline) }
  let(:school_calendar) { create(:school_calendar, unity: unity) }
  let(:classroom) do
    create(:classroom, :with_classroom_trimester_steps, unity: unity, school_calendar: school_calendar)
  end
  # Turma do lançamento, diferente da turma corrente da sessão. É o estado que o
  # redirect do "Salvar e ir para o próximo" produz ao repassar a turma por params.
  let(:other_classroom) do
    create(:classroom, :with_classroom_trimester_steps, unity: unity, school_calendar: school_calendar)
  end

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
    allow(controller).to receive(:current_unity).and_return(unity)
    # Pré-condição da action: sem disciplina conceitual o #new redireciona antes
    # de montar o registro, que é o objeto destes exemplos
    allow(controller).to receive(:teacher_discipline_score_types).and_return([ScoreTypes::CONCEPT])
    allow(controller).to receive(:teacher_differentiated_discipline_score_types).and_return([])
    request.env['REQUEST_PATH'] = ''
  end

  describe 'GET #new' do
    context 'when the classroom comes from params' do
      it 'keeps the classroom of the record instead of the current one' do
        get :new, params: {
          locale: 'pt-BR',
          conceptual_exam: { classroom_id: other_classroom.id }
        }

        expect(assigns(:conceptual_exam).classroom).to eq(other_classroom)
      end
    end

    context 'when there are no params' do
      it 'falls back to the current classroom' do
        get :new, params: { locale: 'pt-BR' }

        expect(assigns(:conceptual_exam).classroom).to eq(classroom)
      end
    end

    context 'when the classroom in params cannot be resolved' do
      # Turma inexistente ou descartada (Classroom tem default_scope kept):
      # sem a turma o restante do fluxo desreferencia a associação
      it 'falls back to the current classroom' do
        get :new, params: {
          locale: 'pt-BR',
          conceptual_exam: { classroom_id: 0 }
        }

        expect(assigns(:conceptual_exam).classroom).to eq(classroom)
      end
    end
  end

  describe '#form_classroom' do
    it 'returns the classroom of the record' do
      controller.instance_variable_set(
        :@conceptual_exam,
        ConceptualExam.new(classroom: other_classroom)
      )

      expect(controller.send(:form_classroom)).to eq(other_classroom)
    end

    it 'falls back to the current classroom when the record has none' do
      controller.instance_variable_set(:@conceptual_exam, ConceptualExam.new)

      expect(controller.send(:form_classroom)).to eq(classroom)
    end
  end
end
