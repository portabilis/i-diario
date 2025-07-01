require 'rails_helper'

RSpec.describe Api::V2::TeacherClassroomsController, type: :controller do
  let(:teacher) { create(:teacher) }
  let(:classroom) { create(:classroom) }
  let(:unity) { create(:unity) }

  around(:each) do |example|
    Entity.find_by_domain("test.host").using_connection do
      example.run
    end
  end

  describe 'GET #index' do
    before do
      request.env['REQUEST_PATH'] = '/api/v2/teacher_classrooms'
    end

    context 'when teacher_id and unity_id are present' do
      let(:school_calendar) { create(:school_calendar, unity: unity, opened_year: true) }

      before do
        classroom.update!(unity: unity, year: school_calendar.year)
        create(:teacher_discipline_classroom, teacher: teacher, classroom: classroom)
      end

      it 'returns teacher classrooms' do
        params = {
          teacher_id: teacher.id,
          unity_id: unity.id,
          format: "json",
          locale: "en"
        }

        get :index, params: params, xhr: true

        expect(response).to have_http_status(:success)
        expect(assigns(:classrooms)).to include(classroom)
      end
    end

    context 'when teacher_id or unity_id are not present' do
      it 'returns nothing when teacher_id is missing' do
        params = {
          unity_id: unity.id,
          format: "json",
          locale: "en"
        }

        get :index, params: params, xhr: true

        expect(response).to have_http_status(:success)
        expect(assigns(:classrooms)).to be_nil
      end

      it 'returns nothing when unity_id is missing' do
        params = {
          teacher_id: teacher.id,
          format: "json",
          locale: "en"
        }

        get :index, params: params, xhr: true

        expect(response).to have_http_status(:success)
        expect(assigns(:classrooms)).to be_nil
      end
    end
  end

  describe 'GET #has_activities' do
    before do
      request.env['REQUEST_PATH'] = '/api/v2/teacher_classrooms/has_activities'
    end

    context 'when teacher and classroom exist' do
      let(:teacher_classroom_activity) { instance_double(Api::TeacherClassroomActivity) }

      before do
        allow(Api::TeacherClassroomActivity).to receive(:new)
          .with(teacher.id, classroom.id)
          .and_return(teacher_classroom_activity)
      end

      it 'returns true when there are activities' do
        allow(teacher_classroom_activity).to receive(:any_activity?).and_return(true)

        params = {
          teacher_id: teacher.api_code,
          classroom_id: classroom.api_code,
          format: "json",
          locale: "en"
        }

        get :has_activities, params: params, xhr: true

        expect(response).to have_http_status(:success)
        json = ActiveSupport::JSON.decode(response.body)
        expect(json).to eq(true)
      end

      it 'returns false when there are no activities' do
        allow(teacher_classroom_activity).to receive(:any_activity?).and_return(false)

        params = {
          teacher_id: teacher.api_code,
          classroom_id: classroom.api_code,
          format: "json",
          locale: "en"
        }

        get :has_activities, params: params, xhr: true

        expect(response).to have_http_status(:success)
        json = ActiveSupport::JSON.decode(response.body)
        expect(json).to eq(false)
      end
    end

    context 'when teacher does not exist' do
      it 'returns 404 error with appropriate message' do
        params = {
          teacher_id: "999999",
          classroom_id: classroom.api_code,
          format: "json",
          locale: "en"
        }

        get :has_activities, params: params, xhr: true

        expect(response).to have_http_status(:not_found)
        json = ActiveSupport::JSON.decode(response.body)
        expect(json['error']).to eq('Professor ou turma não encontrados')
      end
    end

    context 'when classroom does not exist' do
      it 'returns 404 error with appropriate message' do
        params = {
          teacher_id: teacher.api_code,
          classroom_id: "999999",
          format: "json",
          locale: "en"
        }

        get :has_activities, params: params, xhr: true

        expect(response).to have_http_status(:not_found)
        json = ActiveSupport::JSON.decode(response.body)
        expect(json['error']).to eq('Professor ou turma não encontrados')
      end
    end

    context 'when teacher and classroom do not exist' do
      it 'returns 404 error with appropriate message' do
        params = {
          teacher_id: "999999",
          classroom_id: "999999",
          format: "json",
          locale: "en"
        }

        get :has_activities, params: params, xhr: true

        expect(response).to have_http_status(:not_found)
        json = ActiveSupport::JSON.decode(response.body)
        expect(json['error']).to eq('Professor ou turma não encontrados')
      end
    end

    context 'when parameters are blank' do
      it 'returns 404 error when teacher_id is blank' do
        params = {
          teacher_id: "",
          classroom_id: classroom.api_code,
          format: "json",
          locale: "en"
        }

        get :has_activities, params: params, xhr: true

        expect(response).to have_http_status(:not_found)
        json = ActiveSupport::JSON.decode(response.body)
        expect(json['error']).to eq('Professor ou turma não encontrados')
      end

      it 'returns 404 error when classroom_id is blank' do
        params = {
          teacher_id: teacher.api_code,
          classroom_id: "",
          format: "json",
          locale: "en"
        }

        get :has_activities, params: params, xhr: true

        expect(response).to have_http_status(:not_found)
        json = ActiveSupport::JSON.decode(response.body)
        expect(json['error']).to eq('Professor ou turma não encontrados')
      end
    end
  end
end
