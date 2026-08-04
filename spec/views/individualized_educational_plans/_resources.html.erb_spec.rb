require 'rails_helper'

# Renderiza a listagem (tbody) exercitando os policy(...).edit?/destroy? da ERB — que os specs
# de controller não executam. Garante que os botões Editar/Excluir aparecem só quando permitido.
RSpec.describe 'individualized_educational_plans/_resources', type: :view do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:plan) { create(:individualized_educational_plan) }

  def render_resources(edit:, destroy:)
    assign(:individualized_educational_plans, [plan])
    assign(:display_classrooms, { plan.student_id => create(:classroom) })
    allow(view).to receive(:policy).and_return(double(edit?: edit, destroy?: destroy))
    render partial: 'individualized_educational_plans/resources'
  end

  it 'renders the edit link only when editing is allowed' do
    render_resources(edit: true, destroy: false)

    expect(rendered).to include(edit_individualized_educational_plan_path(plan))
  end

  it 'hides the edit link when editing is not allowed' do
    render_resources(edit: false, destroy: false)

    expect(rendered).not_to include(edit_individualized_educational_plan_path(plan))
  end

  it 'renders the destroy link only when destroying is allowed' do
    render_resources(edit: false, destroy: true)

    expect(rendered).to include('data-method="delete"')
  end

  it 'hides the destroy link when destroying is not allowed' do
    render_resources(edit: false, destroy: false)

    expect(rendered).not_to include('data-method="delete"')
  end
end
