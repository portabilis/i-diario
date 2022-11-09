class KnowledgeAreaContentRecordDecorator
  include Decore

  def daily_activities_required?
    general_configuration = GeneralConfiguration.current
    return false if general_configuration.require_daily_activities_record_does_not_require? ||
                    general_configuration.require_daily_activities_record_on_discipline_content_records?

    true
  end

end
