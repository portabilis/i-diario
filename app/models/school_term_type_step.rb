class SchoolTermTypeStep < ApplicationRecord
  include Discardable
  include SchoolCalendarFilterable

  belongs_to :school_term_type

  def to_s
    "#{step_number}º #{school_term_type.description}"
  end

  def self.to_select2(year, unity_id = nil)
    school_term_type_ids = current_year_school_term_types(year, unity_id, false)&.map(&:id)

    return {} if school_term_type_ids.blank?

    elements = undiscarded.where(school_term_type_id: school_term_type_ids).map { |step|
      { id: step.id, name: step.to_s, text: step.to_s }
    }
    elements.insert(0, id: 'empty', name: '<option></option>', text: '')
  end
end
