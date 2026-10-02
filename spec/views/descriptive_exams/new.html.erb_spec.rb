# frozen_string_literal: true

require 'rails_helper'

# O campo "Etapa" é um select2 com input hidden: as opções renderizadas pelo servidor são as que
# a tela oferece. As etapas vêm do calendário da turma quando ela tem um, então a lista precisa
# acompanhar a turma do formulário, que pode não ser a turma selecionada no perfil.
RSpec.describe 'descriptive_exams/new', type: :view do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user, :with_user_role_teacher) }
  let(:unity) { create(:unity) }
  let(:school_calendar) { create(:school_calendar, :with_one_step, unity: unity) }
  let(:profile_classroom) { create_classroom_with_own_steps }
  let(:form_classroom) { create_classroom_with_own_steps }

  around(:each) { |example| entity.using_connection { example.run } }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:current_user_classroom).and_return(profile_classroom)
    allow(user).to receive(:current_role_is_admin_or_employee?).and_return(false)

    assign(:classrooms, [profile_classroom, form_classroom])
    assign(:disciplines, [])
  end

  def create_classroom_with_own_steps
    create(:classroom, :with_classroom_semester_steps, unity: unity, school_calendar: school_calendar)
  end

  def step_ids_of(classroom)
    classroom.calendar.classroom_steps.map(&:id)
  end

  def listed_step_ids
    step_input = Nokogiri::HTML(rendered).at_css('#descriptive_exam_step_id')

    JSON.parse(step_input['data-elements']).map { |element| element['id'] }
  end

  it 'lists the steps of the classroom assigned to the record' do
    assign(:descriptive_exam, DescriptiveExam.new(classroom_id: form_classroom.id))

    render template: 'descriptive_exams/new'

    expect(listed_step_ids).to include(*step_ids_of(form_classroom))
    expect(listed_step_ids).not_to include(*step_ids_of(profile_classroom))
  end

  it 'falls back to the steps of the profile classroom when the record has no classroom' do
    assign(:descriptive_exam, DescriptiveExam.new)

    render template: 'descriptive_exams/new'

    expect(listed_step_ids).to include(*step_ids_of(profile_classroom))
    expect(listed_step_ids).not_to include(*step_ids_of(form_classroom))
  end
end
