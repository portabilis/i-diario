require 'spec_helper'

RSpec.describe OldStepsConceptualValuesController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user, :with_user_role_administrator) }
  let(:classroom) { create(:classroom, :with_classroom_trimester_steps) }
  let(:other_classroom) { create(:classroom, :with_classroom_trimester_steps) }
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

        # O render json: embrulha o array com a root key do controller (AMS),
        # que é o formato consumido pelo form.js (data.old_steps_conceptual_values)
        parsed = JSON.parse(response.body)['old_steps_conceptual_values']
        expect(parsed.size).to eq(1)
        expect(parsed.first['description']).to eq(steps[0].to_s)
        expect(parsed.first['values']).to eq({})
      end
    end

    context 'when the step belongs to another classroom calendar' do
      it 'returns an empty array instead of raising' do
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

    context 'when the step does not exist' do
      it 'returns an empty array' do
        get :index, params: {
          locale: 'pt-BR',
          classroom_id: classroom.id,
          student_id: student.id,
          step_id: 0
        }, format: :json

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq('old_steps_conceptual_values' => [])
      end
    end
  end
end
