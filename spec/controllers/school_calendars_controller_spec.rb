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

  describe 'PATCH #close' do
    let!(:school_calendar) { create(:school_calendar, unity: unity, opened_year: true) }
    let(:params) { { id: school_calendar.id, locale: 'pt-BR' } }

    before do
      allow(SchoolCalendarStatus).to receive(:new).and_return(double(year_closed_in_ieducar?: year_closed_in_ieducar))
      allow_any_instance_of(SchoolCalendar).to receive(:opened_year?).and_return(opened_year)
    end

    shared_examples 'redirects with alert' do |message|
      it "redirects with alert: #{message}" do
        patch :close, params: params
        expect(response).to redirect_to(edit_unity_path(school_calendar.unity))
        expect(flash[:alert]).to eq(message)
      end
    end

    context 'when the school year is still open on i-Educar' do
      let(:year_closed_in_ieducar) { false }
      let(:opened_year) { true }

      include_examples 'redirects with alert', 'Ano letivo ainda está aberto no i-Educar. Não será possível fechar.'
    end

    context 'when the school year is already closed' do
      let(:year_closed_in_ieducar) { true }
      let(:opened_year) { false }

      include_examples 'redirects with alert', 'Ano letivo já está fechado.'
    end

    context 'when the school year is successfully closed' do
      let(:year_closed_in_ieducar) { true }
      let(:opened_year) { true }

      before { allow_any_instance_of(SchoolCalendar).to receive(:update).and_return(true) }

      it 'redirects with success message' do
        patch :close, params: params
        expect(response).to redirect_to(edit_unity_path(school_calendar.unity))
        expect(flash[:notice]).to eq('Ano letivo fechado com sucesso.')
      end
    end

    context 'when an error occurs when closing the school year' do
      let(:year_closed_in_ieducar) { true }
      let(:opened_year) { true }

      before { allow_any_instance_of(SchoolCalendar).to receive(:update).and_return(false) }

      include_examples 'redirects with alert', 'Erro ao fechar ano letivo.'
    end
  end
end
