class SchoolTermType < ApplicationRecord
  include SchoolCalendarFilterable

  has_many :school_term_type_steps, -> { kept }, dependent: :destroy

  def to_s
    description
  end

  def self.to_select2(year, unity_id, add_yearly: true, add_empty_element: true)
    term_types = current_year_school_term_types(year, unity_id, add_yearly)
    elements = term_types.map { |step_type| { id: step_type.id, name: step_type.to_s, text: step_type.to_s } }
    elements.insert(0, id: 'empty', name: '<option></option>', text: '') if add_empty_element

    elements
  end
end
