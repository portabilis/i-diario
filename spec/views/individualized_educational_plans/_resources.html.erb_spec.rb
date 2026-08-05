require 'rails_helper'

# Renderiza a listagem (tbody) exercitando os policy(...).edit?/destroy? da ERB — que os specs
# de controller não executam. Garante que os botões Editar/Excluir aparecem só quando permitido.
RSpec.describe 'individualized_educational_plans/_resources', type: :view do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:plan) { create(:individualized_educational_plan) }

  def render_resources(edit:, destroy:, editable_student: true)
    assign(:individualized_educational_plans, [plan])
    assign(:display_classrooms, { plan.student_id => create(:classroom) })
    assign(:editable_student_ids, editable_student ? Set[plan.student_id] : Set.new)
    allow(view).to receive(:policy).and_return(double(edit?: edit, destroy?: destroy))
    render partial: 'individualized_educational_plans/resources'
  end

  it 'renders the edit link enabled when the student is editable' do
    render_resources(edit: true, destroy: false)

    expect(rendered).to include(edit_individualized_educational_plan_path(plan))
    expect(rendered).not_to include('disabled')
  end

  it 'renders the edit link disabled for a plan the user cannot edit (visible only by authorship)' do
    render_resources(edit: true, destroy: false, editable_student: false)

    expect(rendered).to include(edit_individualized_educational_plan_path(plan))
    expect(rendered).to include('btn btn-success apply_tooltip disabled')
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
