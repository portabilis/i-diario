class BnccObjectivesAndSkillsDecorator
  include Decore
  include Decore::Proxy

  def self.education_fields_by_type(type)
    return ElementaryEducations.to_select(false) if type == 'disciplines'

    return GroupChildEducations.to_select(false) if type == 'group_child_schools'

    return ChildEducations.to_select(false)
  end
end
