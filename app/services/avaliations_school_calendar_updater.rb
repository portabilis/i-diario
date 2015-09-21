class AvaliationsSchoolCalendarUpdater
  attr_reader :name,
              :status

  def initialize(options)
    @name = options["NAME"]
  end

  def update
    if has_params? && update_avaliations_school_calendar
      success
    else
      error
    end
  end

  private

  def has_params?
    name
  end

  def update_avaliations_school_calendar
    entity = Entity.find_by_name(name)
    if entity
      entity.using_connection do
        avaliations = Avaliation.all
        avaliations.each do |avaliation|
          school_calendar = SchoolCalendar.find_by(unity_id: avaliation.unity_id, year: avaliation.test_date.year)

          if school_calendar
            avaliation.school_calendar = school_calendar
            avaliation.save(validate: false)
          end
        end
      end
    else
      false
    end
  end

  def success
    @status = I18n.t('services.avaliations_school_calendar_updater.success')
  end

  def error
    @status = I18n.t('services.avaliations_school_calendar_updater.error')
  end
end
