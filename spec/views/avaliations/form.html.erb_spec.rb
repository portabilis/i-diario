# frozen_string_literal: true

require 'rails_helper'

# O campo "Configuração de avaliação" é um select2 com input hidden: o valor renderizado pelo
# servidor é o que a tela mostra ao professor. Só há mais de uma opção quando as configurações
# do ano são by_school_term (uma por etapa) — nos demais tipos a lista tem um item só.
RSpec.describe 'avaliations/_form', type: :view do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:school_term_type) { create(:school_term_type) }
  let(:user) { create(:user, :with_user_role_teacher) }
  let(:avaliation) { build(:avaliation, test_setting: record_test_setting) }

  around(:each) { |example| entity.using_connection { example.run } }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(user).to receive(:current_unity).and_return(avaliation.classroom.unity)
    allow(user).to receive(:current_role_is_admin_or_employee?).and_return(false)
  end

  # A ordem de criação importa: a tela lista as configurações na ordem devolvida pelo
  # controller, e o defeito era renderizar sempre a primeira delas.
  let(:first_test_setting) { build_test_setting(1) }
  let(:record_test_setting) { build_test_setting(2) }

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

  def assign_form_options(record, test_settings)
    assign(:avaliation, record)
    assign(:test_settings, test_settings)
    assign(:classrooms, Classroom.where(id: record.classroom_id))
    assign(:disciplines, Discipline.where(id: record.discipline_id))
    assign(:grades, Grade.where(id: record.grade_ids))
    assign(:allow_automatic_avaliation_recovery, false)
    assign(:force_recovery_creation, false)
  end

  def rendered_test_setting_id
    Nokogiri::HTML(rendered).at_css('#avaliation_test_setting_id')['value']
  end

  it 'renders the test setting assigned to the record instead of the first of the list' do
    assign_form_options(avaliation, [first_test_setting, record_test_setting])

    render partial: 'avaliations/form'

    expect(rendered_test_setting_id).to eq(record_test_setting.id.to_s)
  end

  it 'falls back to the first test setting of the list when the record has none' do
    listed = [first_test_setting, record_test_setting]
    avaliation.test_setting = nil
    assign_form_options(avaliation, listed)

    render partial: 'avaliations/form'

    expect(rendered_test_setting_id).to eq(first_test_setting.id.to_s)
  end

  it 'renders no value when the record has none and the list is empty' do
    avaliation.test_setting = nil
    assign_form_options(avaliation, [])

    render partial: 'avaliations/form'

    expect(rendered_test_setting_id).to be_nil
  end
end
