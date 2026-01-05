require 'rails_helper'

RSpec.describe ObservationRecordReportController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  let(:unity) { create(:unity) }
  let(:current_teacher) { create(:teacher) }
  let(:other_teacher) { create(:teacher) }
  let(:discipline) { create(:discipline) }
  let(:other_discipline) { create(:discipline) }
  let(:school_calendar) {
    create(
      :school_calendar,
      :with_trimester_steps,
      unity: unity
    )
  }

  let(:classroom) {
    create(
      :classroom,
      :score_type_numeric,
      :with_teacher_discipline_classroom,
      teacher: current_teacher,
      discipline: discipline,
      school_calendar: school_calendar,
      year: school_calendar.year,
      unity: unity
    )
  }

  let(:user) do
    create(
      :user_with_user_role,
      admin: false,
      teacher_id: current_teacher.id,
      current_unity_id: unity.id,
      current_school_year: classroom.year,
      current_classroom_id: classroom.id,
      current_discipline_id: discipline.id
    )
  end

  before(:each) do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:current_school_year).and_return(classroom.year)
  end

  describe 'GET #disciplines' do
    context 'when teacher_id is blank' do
      it 'returns an empty disciplines array' do
        get :disciplines, params: { locale: 'pt-BR', format: 'json', teacher_id: '' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['disciplines']).to eq([])
      end
    end

    context 'when classroom_id is a specific classroom' do
      context 'when classroom_id is blank' do
        it 'returns an empty disciplines array' do
          get :disciplines, params: {
            locale: 'pt-BR',
            format: 'json',
            teacher_id: current_teacher.id,
            classroom_id: ''
          }

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['disciplines']).to eq([])
        end
      end

      it 'returns disciplines filtered by classroom and teacher' do
        classroom

        get :disciplines, params: {
          locale: 'pt-BR',
          format: 'json',
          teacher_id: current_teacher.id,
          classroom_id: classroom.id
        }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['disciplines']).to be_an(Array)
        expect(json_response['disciplines'].map { |d| d['id'] }).to include(discipline.id)
      end

      it 'does not return disciplines from other teachers' do
        classroom

        get :disciplines, params: {
          locale: 'pt-BR',
          format: 'json',
          teacher_id: other_teacher.id,
          classroom_id: classroom.id
        }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['disciplines'].map { |d| d['id'] }).not_to include(discipline.id)
      end
    end

    context 'when classroom_id is "all"' do
      context 'when unity_id is blank' do
        it 'returns an empty disciplines array' do
          get :disciplines, params: {
            locale: 'pt-BR',
            format: 'json',
            teacher_id: current_teacher.id,
            classroom_id: 'all',
            unity_id: ''
          }

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['disciplines']).to eq([])
        end
      end

      it 'returns disciplines filtered by unity and teacher' do
        classroom

        get :disciplines, params: {
          locale: 'pt-BR',
          format: 'json',
          teacher_id: current_teacher.id,
          classroom_id: 'all',
          unity_id: unity.id
        }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['disciplines']).to be_an(Array)
        expect(json_response['disciplines'].map { |d| d['id'] }).to include(discipline.id)
      end
    end

    it 'returns disciplines with id, name and text attributes' do
      classroom

      get :disciplines, params: {
        locale: 'pt-BR',
        format: 'json',
        teacher_id: current_teacher.id,
        classroom_id: classroom.id
      }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response['disciplines'].first).to have_key('id')
      expect(json_response['disciplines'].first).to have_key('name')
      expect(json_response['disciplines'].first).to have_key('text')
    end
  end
end
