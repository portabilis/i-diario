class SchoolCalendarDisciplineGradesSynchronizer < BaseSynchronizer
  def synchronize!
    update_school_calendar_discipline_grade(
      HashDecorator.new(
        api.fetch(
          escola: unity_api_code
        )['escolas']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  def api_class
    IeducarApi::SchoolCalendarDisciplineGrades
  end

  def update_school_calendar_discipline_grade(unity_grade_discipline_years)
    existing_school_calendar_discipline_grade = []

    unity_grade_discipline_years.each do |unity_grade_discipline_year_record|
      @unity = unity(unity_grade_discipline_year_record.escola_id)

      next if @unity.blank?

      school_calendar_discipline_grade_records = combine_discipline_years_and_steps(
        unity_grade_discipline_year_record.series_disciplinas_anos_letivos,
        unity_grade_discipline_year_record.series_disciplinas_etapas_utilizadas
      )

      school_calendar_discipline_grade_records.each do |_,record|
        process_combined_record(record, existing_school_calendar_discipline_grade)
      end
    end

    # destroy_removed_disciplines(existing_school_calendar_discipline_grade)
  end

  def combine_discipline_years_and_steps(discipline_years, discipline_steps)
    combined_records = {}

    discipline_years.map do |discipline_year|
      grade_api_code = discipline_year[:serie_id]
      combined_records[grade_api_code] ||= {
        grade_api_code: grade_api_code, years: [], steps: [], discipline_api_code: []
      }

      discipline_year[:disciplinas_anos_letivos].each do |discipline_and_years|
        discipline_api_code = discipline_and_years.to_h.keys.first.to_s
        years = discipline_and_years.to_h.values.flatten

        combined_records[grade_api_code][:discipline_api_code] << discipline_api_code
        combined_records[grade_api_code][:years].concat(years)
      end
    end

    discipline_steps.map do |step_record|
      grade_api_code = step_record[:serie_id]
      combined_records[grade_api_code] ||= {
        grade_api_code: grade_api_code, years: [], steps: [], discipline_api_code: []
      }

      step_record[:disciplinas_etapas_utilizadas].each do |discipline_and_steps|
        discipline_api_code = discipline_and_steps.to_h.keys.first.to_s
        steps = discipline_and_steps.to_h.values.flatten

        unless combined_records[grade_api_code][:discipline_api_code].include?(discipline_api_code)
          combined_records[grade_api_code][:discipline_api_code] << discipline_api_code
        end
        combined_records[grade_api_code][:steps].concat(steps) if steps.any?
      end
    end

    combined_records
  end

  def process_combined_record(record, existing_school_calendar_discipline_grade)
    grade = find_valid_grade(record[:grade_api_code])

    return if grade.blank?

    record[:discipline_api_code].each do |discipline_api_code|
      discipline = discipline(discipline_api_code)

      next if discipline.blank?

      record[:years].each do |year|
        process_school_calendar(
          year,
          discipline,
          grade,
          existing_school_calendar_discipline_grade,
          record[:steps]
        )
      end
    end
  end

  def process_school_calendar(
    year,
    discipline,
    grade,
    existing_school_calendar_discipline_grade,
    steps
  )
    school_calendar = SchoolCalendar.find_by(year: year, unity: @unity)

    return if school_calendar.blank?

    school_calendar_discipline_grade = SchoolCalendarDisciplineGrade.find_or_initialize_by(
      school_calendar_id: school_calendar.id,
      discipline_id: discipline.id,
      grade_id: grade.id
    )

    school_calendar_discipline_grade.steps = steps.presence ? steps : nil

    school_calendar_discipline_grade.save if school_calendar_discipline_grade.changed?

    return if school_calendar_discipline_grade.errors.any?

    existing_school_calendar_discipline_grade << school_calendar_discipline_grade.id
  end

  def destroy_removed_disciplines(existing_school_calendar_discipline_grade)
    return if @unity.nil?

    SchoolCalendarDisciplineGrade
      .where.not(id: existing_school_calendar_discipline_grade)
      .joins(:school_calendar)
      .where(school_calendars: { unity_id: @unity.id })
      .destroy_all
  end

  def find_valid_grade(grade_api_code)
    grade = grade(grade_api_code)
    grade.presence ? grade : nil
  end
end
