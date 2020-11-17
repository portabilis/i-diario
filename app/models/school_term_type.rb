class SchoolTermType < ActiveRecord::Base
  has_many :school_term_type_steps, dependent: :destroy

  def to_s
    description
  end

  def self.to_select2(add_yearly: false, add_yearly_value: false, add_empty_element: true)
    elements = all.map { |step_type| { id: step_type.id, name: step_type.to_s, text: step_type.to_s } }
    elements.insert(0, id: 'empty', name: '<option></option>', text: '') if add_empty_element

    if add_yearly
      yearly_entry = { id: '', name: 'Anual', text: 'Anual' }
      yearly_entry[:id] = 'yearly' if add_yearly_value

      elements << yearly_entry
    end

    elements
  end
end
