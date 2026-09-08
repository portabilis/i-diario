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

  it 'renders no value when nothing was submitted and the list is empty' do
    assign_form_options(AvaliationMultipleCreatorForm.new, [])

    render template: 'avaliations/multiple_classrooms'

    expect(rendered_test_setting_id).to be_nil
  end
end
