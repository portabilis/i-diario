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

      unity_grade_discipline_year_record.series_disciplinas_anos_letivos.each do |grade_discipline_year|
        grade = grade(grade_discipline_year.serie_id)

        next if grade.blank?

        grade_discipline_year.disciplinas_anos_letivos.each do |discipline_and_years|
          discipline_api_code = discipline_and_years.to_h.keys.first.to_s
          years = discipline_and_years.to_h.values.flatten
          discipline = discipline(discipline_api_code)

          next if discipline.blank?

          years.each do |year|
            school_calendar = SchoolCalendar.find_by(year: year, unity: @unity)

            next if school_calendar.blank?

            school_calendar_discipline_grade = SchoolCalendarDisciplineGrade.find_or_create_by(
              school_calendar_id: school_calendar.id,
              discipline_id: discipline.id,
              grade_id: grade.id
            )

            existing_school_calendar_discipline_grade << school_calendar_discipline_grade.try(:id)
          end
        end
      end
    end

    destroy_removed_disciplines(existing_school_calendar_discipline_grade)
  end

  def destroy_removed_disciplines(existing_school_calendar_discipline_grade)
    return if @unity.nil?

    SchoolCalendarDisciplineGrade.where.not(id: existing_school_calendar_discipline_grade).joins(:school_calendar)
                                 .where(school_calendars: { unity_id: @unity.try(:id) }).destroy_all
  end
end
