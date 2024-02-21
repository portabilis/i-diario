require 'spec_helper'

RSpec.describe DisciplineContentRecordsController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
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
  let(:unity) { create(:unity) }
  let(:school_calendar) { create(:school_calendar, :with_one_step, unity: unity, opened_year: true) }
  let(:current_teacher) { create(:teacher) }
  let(:discipline) { create(:discipline) }
  let(:classroom) {
    create(
      :classroom,
      :with_teacher_discipline_classroom,
      :with_classroom_trimester_steps,
      :score_type_numeric,
      unity: unity,
      teacher: current_teacher,
      discipline: discipline,
      school_calendar: school_calendar
    )
  }
  let(:content) { create(:content) }

  let(:params) {
    {
      locale: 'pt-BR',
      discipline_content_record: {
        discipline_id: discipline.id,
        content_record_attributes: {
          classroom_id: classroom.id,
          unity_id: unity.id,
          daily_activities_record: 'test',
          record_date: '2017-02-28',
          content_ids: [content.id]
        }
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
    allow(controller).to receive(:current_teacher).and_return(current_teacher)
    allow(controller).to receive(:current_teacher_id).and_return(current_teacher.id)
    request.env['REQUEST_PATH'] = ''
  end

  describe 'POST #create when daily activities record is required' do
    before(:each) do
      GeneralConfiguration.current
                          .update(
                            require_daily_activities_record:
                              RequireDailyActivitiesRecordTypes::ON_DISCIPLINE_CONTENT_RECORDS
                          )
    end

    it 'not having a daily activities record fails to create and renders the new template' do
      params[:discipline_content_record][:content_record_attributes].delete(:daily_activities_record)
      post :create, params: params.merge(params)
      expect(response).to render_template(:new)
    end

    it 'having a daily activities record creates and redirects to discipline content records path' do
      post :create, params: params
      expect(response).to redirect_to(discipline_content_records_path)
    end

  end

  describe 'POST #create when daily activities record is not required' do
    before(:each) do
      GeneralConfiguration.current
                          .update(
                            require_daily_activities_record:
                              RequireDailyActivitiesRecordTypes::DOES_NOT_REQUIRE
                          )
    end

    it 'not having a daily activities record creates and redirects to discipline content records path' do
      params[:discipline_content_record][:content_record_attributes].delete(:daily_activities_record)
      post :create, params: params.merge(params)
      expect(response).to redirect_to(discipline_content_records_path)
    end

  end
end
