# frozen_string_literal: true

require 'rails_helper'

# Tela de criação de avaliações para várias turmas de uma vez. O campo "Configuração de
# avaliação" tem o mesmo select2 com input hidden do formulário de avaliação única, e o
# form object é re-renderizado quando a validação falha.
RSpec.describe 'avaliations/multiple_classrooms', type: :view do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:school_term_type) { create(:school_term_type) }
  let(:user) { create(:user, :with_user_role_teacher) }
  let(:unity) { create(:unity) }
  let(:discipline) { create(:discipline) }
  let(:first_test_setting) { build_test_setting(1) }
  let(:submitted_test_setting) { build_test_setting(2) }

  around(:each) { |example| entity.using_connection { example.run } }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:classrooms_for_multiple_classrooms).and_return([])
    allow(user).to receive(:current_unity).and_return(unity)
    allow(user).to receive(:current_role_is_admin_or_employee?).and_return(false)
  end

  def build_test_setting(step_number)
    create(
      :test_setting,
      year: 2026,
      exam_setting_type: ExamSettingTypes::BY_SCHOOL_TERM,
      school_term_type_step: create(:school_term_type_step,
                                    school_term_type: school_term_type,
                                    step_number: step_number)
    )
  end

  def assign_form_options(form, test_settings)
    assign(:avaliation_multiple_creator_form, form)
    assign(:test_settings, test_settings)
    assign(:disciplines, Discipline.where(id: discipline.id))
    assign(:number_of_classes, 5)
    assign(:allow_automatic_avaliation_recovery, false)
    assign(:force_recovery_creation, false)
  end

  def rendered_test_setting_id
    Nokogiri::HTML(rendered).at_css('#avaliation_multiple_creator_form_test_setting_id')['value']
  end

  # Cada mensagem precisa sair no campo que o professor pode corrigir. A coluna Turma não tem campo
  # para corrigir Descrição, Peso ou Data: ela só resume o que é problema daquela turma.
  context 'when the submitted form is invalid' do
    let(:classroom) { create(:classroom, :score_type_numeric, unity: unity) }
    let(:teacher) { create(:teacher) }
    let(:calendar) { create(:school_calendar, :with_one_step, unity: unity) }
    let(:breakable_test_setting) { create(:test_setting_with_sum_calculation_type_that_allow_break_up) }
    let(:grade) do
      create(:school_calendar_discipline_grade, school_calendar: calendar, discipline: discipline).grade
    end

    let!(:teacher_discipline_classroom) do
      create(:teacher_discipline_classroom, teacher: teacher, discipline: discipline,
                                            classroom: classroom)
    end

    def invalid_form
      AvaliationMultipleCreatorForm.new(
        'unity_id' => unity.id,
        'discipline_id' => discipline.id,
        'school_calendar_id' => calendar.id,
        'test_setting_id' => breakable_test_setting.id,
        'test_setting_test_id' => breakable_test_setting.tests.first.id,
        'description' => '',
        'weight' => '',
        'avaliations_attributes' => {
          '0' => { 'include' => '1', 'classroom_id' => classroom.id.to_s,
                   'test_date' => '', 'grade_ids' => grade.id.to_s }
        },
        teacher_id: teacher.id
      ).tap(&:valid?)
    end

    def messages_by_input
      Nokogiri::HTML(rendered).css('.control-group').each_with_object({}) do |group, messages|
        input = group.at_css('input, textarea, select')
        error = group.at_css('.help-inline')&.text&.strip

        next if input.nil? || error.blank?

        messages[input['id']] = error
      end
    end

    it 'renders each message under the field that owns it' do
      assign_form_options(invalid_form, [breakable_test_setting])

      render template: 'avaliations/multiple_classrooms'

      expect(messages_by_input).to eq(
        'avaliation_multiple_creator_form_description' => 'não pode ficar em branco',
        'avaliation_multiple_creator_form_weight' => 'não pode ficar em branco',
        'avaliation_multiple_creator_form_avaliations_attributes_0_test_date' => 'deve ser uma data válida'
      )
    end
  end

  it 'renders the test setting submitted by the user instead of the first of the list' do
    form = AvaliationMultipleCreatorForm.new(test_setting_id: submitted_test_setting.id)
    assign_form_options(form, [first_test_setting, submitted_test_setting])

    render template: 'avaliations/multiple_classrooms'

    expect(rendered_test_setting_id).to eq(submitted_test_setting.id.to_s)
  end

  it 'falls back to the first test setting of the list when nothing was submitted' do
    listed = [first_test_setting, submitted_test_setting]
    assign_form_options(AvaliationMultipleCreatorForm.new, listed)

    render template: 'avaliations/multiple_classrooms'

    expect(rendered_test_setting_id).to eq(first_test_setting.id.to_s)
  end

  it 'falls back to the first test setting of the list when the submitted value is blank' do
    listed = [first_test_setting, submitted_test_setting]
    assign_form_options(AvaliationMultipleCreatorForm.new(test_setting_id: ''), listed)

    render template: 'avaliations/multiple_classrooms'

    expect(rendered_test_setting_id).to eq(first_test_setting.id.to_s)
  end

  it 'renders no value when nothing was submitted and the list is empty' do
    assign_form_options(AvaliationMultipleCreatorForm.new, [])

    render template: 'avaliations/multiple_classrooms'

    expect(rendered_test_setting_id).to be_nil
  end
end
