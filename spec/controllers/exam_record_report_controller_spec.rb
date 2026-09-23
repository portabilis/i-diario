require 'rails_helper'

RSpec.describe ExamRecordReportController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  let(:unity) { create(:unity) }
  let(:teacher) { create(:teacher) }
  let(:discipline) { create(:discipline) }
  let(:school_calendar) { create(:school_calendar, :with_trimester_steps, unity: unity) }

  let(:classroom) do
    create(
      :classroom,
      :with_teacher_discipline_classroom,
      teacher: teacher,
      discipline: discipline,
      school_calendar: school_calendar,
      year: school_calendar.year,
      unity: unity
    )
  end

  let(:admin_user) do
    create(
      :user,
      :with_user_role_administrator,
      assumed_teacher_id: teacher.id,
      current_unity_id: unity.id,
      current_school_year: classroom.year,
      current_classroom_id: classroom.id,
      current_discipline_id: discipline.id
    )
  end

  before do
    sign_in(admin_user)
    allow(controller).to receive(:current_school_year).and_return(classroom.year)
  end

  describe 'POST #report' do
    render_views

    # O layout referencia os pacotes do webpack, que não são compilados no ambiente de teste.
    # Sem isso a renderização estoura, o tratamento genérico de erro assume e a requisição
    # redireciona antes de o formulário chegar à resposta.
    before do
      allow_any_instance_of(ActionView::Base).to receive(:javascript_pack_tag).and_return('')
      allow_any_instance_of(ActionView::Base).to receive(:stylesheet_pack_tag).and_return('')
    end

    def post_report(form_params)
      post :report, params: { locale: 'pt-BR', exam_record_report_form: form_params }
    end

    it 'renders the form with validation errors when the classroom is blank' do
      post_report(unity_id: unity.id, classroom_id: '', discipline_id: '', school_calendar_step_id: '')

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:form)
      expect(response.body).to include('não pode ficar em branco')
      expect(assigns(:exam_record_report_form).errors).to include(:classroom_id, :discipline_id)
      expect(assigns(:school_calendar_steps)).to match_array(school_calendar.steps)
    end

    it 'renders the form with validation errors when the unity and the classroom are blank' do
      post_report(unity_id: '', classroom_id: '', discipline_id: '', school_calendar_step_id: '')

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:form)
      expect(response.body).to include('não pode ficar em branco')
      expect(assigns(:exam_record_report_form).errors).to include(:unity_id, :classroom_id)
      expect(assigns(:school_calendar_steps)).to be_empty
    end
  end
end
