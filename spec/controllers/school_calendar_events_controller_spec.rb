require 'spec_helper'

RSpec.describe SchoolCalendarEventsController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user, :with_user_role_administrator) }
  let(:user_role) { user.user_roles.first }
  let(:unity) { user_role.unity }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps, unity: unity) }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  before do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:current_unity).and_return(unity)
    request.env['REQUEST_PATH'] = ''
  end

  describe 'GET #index' do
    let(:school_calendar) { classroom.calendar.school_calendar }
    let(:school_calendar_event) { create(:school_calendar_event, school_calendar: school_calendar) }
    let(:other_school_calendar_event) { create(:school_calendar_event, school_calendar: school_calendar) }

    shared_examples 'test_user_role_access' do
      before do
        get :index, params: { school_calendar_id: school_calendar.id, locale: 'pt-BR' }
      end

      it 'lists all school calendar events by school calendar' do
        expect(assigns(:school_calendar_events)).to include(
          school_calendar_event,
          other_school_calendar_event
        )
      end
    end

    context 'user has current_user_role selected' do
      it { expect(user.current_user_role).to be_present }
    end

    context 'user has not current_user_role selected' do
      before do
        user.current_user_role = nil
        user.save!
      end

      it { expect(user.current_user_role).to_not be_present }
    end
  end
end
