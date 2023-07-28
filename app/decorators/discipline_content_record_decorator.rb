class DisciplineContentRecordDecorator
  include Decore

  def daily_activities_required?
    general_configuration = GeneralConfiguration.current
    return false if general_configuration.require_daily_activities_record_does_not_require? ||
                    general_configuration.require_daily_activities_record_on_knowledge_area_content_records?

    true
  end

end
