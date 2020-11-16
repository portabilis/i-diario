class SchoolTermTypeStep < ActiveRecord::Base
  belongs_to :school_term_type

  def to_s
    "#{step_number}º #{school_term_type.description}"
  end

  def self.to_select2
    elements = all.map { |step| { id: step.id, name: step.to_s, text: step.to_s } }
    elements.insert(0, id: 'empty', name: '<option></option>', text: '')
  end
end
