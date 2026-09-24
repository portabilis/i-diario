# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AttendanceRecordReportByStudentsController, type: :controller do
  let(:report_year) { Date.current.year }
  let(:unity) { create(:unity) }
  let(:discipline) { create(:discipline) }
  let(:teacher) { create(:teacher) }
  let!(:school_calendar) { create(:school_calendar, unity: unity, year: report_year) }

  # O calendário vai pela transient da factory: a trait cria um por conta
  # própria quando não recebe, e o segundo calendário da mesma unidade e ano é
  # inválido.
  let(:classroom) do
    create(
      :classroom,
      :with_classroom_trimester_steps,
      unity: unity,
      year: report_year,
      school_calendar: school_calendar
    )
  end

  let(:user) do
    create(
      :user,
      :with_user_role_administrator,
      admin: true,
      teacher_id: teacher.id,
      current_unity_id: unity.id,
      current_school_year: report_year,
      current_classroom_id: classroom.id,
      current_discipline_id: discipline.id
    )
  end

  let(:report_params) do
    {
      unity_id: unity.id,
      classroom_id: classroom.id.to_s,
      period: Periods::FULL,
      start_at: "01/02/#{report_year}",
      end_at: "30/11/#{report_year}",
      school_calendar_year: report_year,
      current_user_id: user.id
    }
  end

  around(:each) do |example|
    Entity.find_by_domain('test.host').using_connection do
      example.run
    end
  end

  before do
    user_role = user.user_roles.first
    user_role.unity = unity
    user_role.save!

    user.current_user_role = user_role
    user.save!

    sign_in(user)
    allow(controller).to receive(:current_unity).and_return(unity)
    allow(controller).to receive(:current_user_classroom).and_return(classroom)
    allow(controller).to receive(:current_teacher).and_return(teacher)
    request.env['REQUEST_PATH'] = ''

    # A busca dos alunos é coberta pelo form e pelo service; aqui o alvo é o
    # motor e o layout com que o PDF é gerado. Sem matrícula na turma o
    # info_students_list levanta DailyFrequenciesNotFoundError e a action cai no
    # render :form antes de chegar na geração.
    allow_any_instance_of(AttendanceRecordReportByStudentForm).to receive(:select_all_classrooms)
      .and_return([classroom])
    allow_any_instance_of(AttendanceRecordReportByStudentForm).to receive(:info_students_list)
      .and_return([])
    allow(AttendanceRecordReportByStudent).to receive(:call).and_return({})
    allow(ReportGenerator).to receive(:call).and_return(double(body: '%PDF-fake'))
  end

  describe '#report' do
    # O PDF sai do motor PlutoBook com o layout de paged media compartilhado.
    # Cabeçalho, rodapé e numeração vivem no CSS do report_pluto, então trocar
    # layout ou driver aqui muda o documento entregue ao usuário.
    it 'renders through the pluto engine with the report_pluto layout' do
      expect(controller).to receive(:render_to_string).with(
        action: :report, layout: 'report_pluto'
      ).and_return('<html></html>')

      post :report, params: { locale: 'pt-BR', attendance_record_report_by_student_form: report_params }

      expect(ReportGenerator).to have_received(:call).with('<html></html>', driver: :pluto)
    end

    it 'sends the generated pdf inline' do
      post :report, params: { locale: 'pt-BR', attendance_record_report_by_student_form: report_params }

      expect(response.body).to eq('%PDF-fake')
      expect(response.header['Content-Type']).to include('application/pdf')
    end

    context 'when the form is invalid' do
      it 'renders the form back instead of calling the report service' do
        post :report, params: {
          locale: 'pt-BR',
          attendance_record_report_by_student_form: report_params.merge(start_at: '')
        }

        expect(response).to render_template(:form)
        expect(ReportGenerator).to_not have_received(:call)
      end
    end
  end
end
