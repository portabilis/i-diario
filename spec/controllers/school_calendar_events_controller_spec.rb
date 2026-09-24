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

  # Cobre o vínculo entre o controller e o DateValidation: sem o include, a limpeza da
  # data derruba a requisição em vez de devolver o formulário.
  describe 'POST #create' do
    let(:school_calendar) { classroom.calendar.school_calendar }

    context 'when the informed date does not exist' do
      it 'renders the form clearing the invalid date' do
        post :create, params: {
          school_calendar_id: school_calendar.id,
          locale: 'pt-BR',
          frequency_deletion_confirmed: true,
          school_calendar_event: {
            description: 'Evento',
            event_type: EventTypes::NO_SCHOOL,
            coverage: 'by_unity',
            periods: Periods::VESPERTINE,
            legend: 'A',
            start_date: '31/06/2026',
            end_date: '31/06/2026'
          }
        }

        expect(response).to render_template(:new)
        expect(assigns(:school_calendar_event).start_date).to be_blank
      end
    end
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

  describe 'PATCH #update' do
    let(:school_calendar) { create(:school_calendar, :with_trimester_steps, unity: unity) }
    let(:step) { school_calendar.steps.first }
    let!(:event) do
      create(
        :school_calendar_event,
        school_calendar: school_calendar,
        coverage: 'by_unity',
        event_type: EventTypes::NO_SCHOOL,
        periods: Periods::VESPERTINE,
        legend: 'A',
        start_date: step.start_at,
        end_date: step.start_at
      )
    end

    let(:other_grade) { create(:grade) }
    let(:other_classroom) { create(:classroom) }
    let(:other_course) { create(:course) }

    before do
      allow_any_instance_of(SchoolCalendarEvent).to receive(:save).and_return(true)
      allow(SchoolCalendarEventDays).to receive(:update_school_days)
    end

    def patch_update(attributes, confirmed: true)
      patch :update, params: {
        school_calendar_id: school_calendar.id,
        id: event.id,
        locale: 'pt-BR',
        frequency_deletion_confirmed: confirmed,
        school_calendar_event: attributes
      }
    end

    # Cada um dos campos de escopo deve, ao mudar, disparar a limpeza com scope_changed true.
    {
      periods: -> { "#{Periods::VESPERTINE},#{Periods::MATUTINAL}" },
      grade_id: -> { other_grade.id },
      classroom_id: -> { other_classroom.id },
      course_id: -> { other_course.id }
    }.each do |field, value|
      context "when #{field} changes and deletion is confirmed" do
        it 'triggers the frequency cleanup with scope_changed true' do
          patch_update(field => instance_exec(&value))

          expect(SchoolCalendarEventDays).to have_received(:update_school_days).with(
            [school_calendar], [event], 'update', step.start_at, step.start_at,
            event_type_changed: false, scope_changed: true
          )
        end
      end
    end

    context 'when the event scope changes but deletion is NOT confirmed' do
      it 'blocks the deletion (fail-closed) and does not call the cleanup' do
        patch_update({ periods: "#{Periods::VESPERTINE},#{Periods::MATUTINAL}" }, confirmed: false)

        expect(SchoolCalendarEventDays).not_to have_received(:update_school_days)
        expect(response).to render_template(:edit)
      end
    end

    context 'when only a non-scope field changes (description)' do
      it 'does not trigger the frequency cleanup' do
        patch_update({ description: 'Nova descrição do evento' }, confirmed: false)

        expect(SchoolCalendarEventDays).not_to have_received(:update_school_days)
      end
    end
  end
end
