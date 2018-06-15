class TeachingPlanDecorator
  include Decore
  include Decore::Proxy

  def author
    return I18n.t('enumerations.plans_authors.my_plans') if component.teacher_id

    I18n.t('enumerations.plans_authors.others')
  end
end
