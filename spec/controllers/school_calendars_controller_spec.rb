require 'spec_helper'

RSpec.describe SchoolCalendarsController, type: :controller do
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
    let!(:school_calendar) { classroom.calendar.school_calendar }
    let!(:other_school_calendar) { create(:school_calendar) }

    shared_examples 'test_user_role_access' do
      context 'when user is administrator' do
        before do
          get :index, params: { locale: 'pt-BR' }
        end

        it 'lists all school calendars' do
          expect(assigns(:school_calendars)).to include(
            school_calendar,
            other_school_calendar
          )
        end
      end

      context 'when user is teacher' do
        before do
          user_role.role = create(:role)
          user_role.save!

          get :index, params: { locale: 'pt-BR' }
        end

        it 'lists only school calendar with role unity' do
          expect(assigns(:school_calendars)).to eq([school_calendar])
        end
      end
    end

    context 'user has current_user_role selected' do
      it_behaves_like 'test_user_role_access'
    end

    context 'user has not current_user_role selected' do
      before do
        user.current_user_role = nil
        user.save!
      end

      it_behaves_like 'test_user_role_access'
    end
  end
end
