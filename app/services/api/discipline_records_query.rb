# frozen_string_literal: true

module Api
  # Shared query logic for resolving discipline record filters
  class DisciplineRecordsQuery # rubocop:disable Metrics/ClassLength
    attr_reader :classroom_ids, :discipline_ids, :year

    def initialize(unities:, courses:, grades:, disciplines:, year:) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @unities = Array(unities).map(&:to_s).reject(&:blank?)
      @courses = Array(courses).map(&:to_s).reject(&:blank?)
      @grades = Array(grades).map(&:to_s).reject(&:blank?)
      @disciplines = Array(disciplines).map(&:to_s).reject(&:blank?)
      @year = year.to_i

      resolve_ids
    end

    def daily_frequencies
      return DailyFrequency.none if @no_results

      filter_by_discipline(
        filter_by_start_date(DailyFrequency, :classroom_id, :frequency_date)
      )
    end

    def avaliations
      return Avaliation.none if @no_results

      filter_by_discipline(
        filter_by_start_date(Avaliation, :classroom_id, :test_date)
      )
    end

    def conceptual_exams
      return ConceptualExam.none if @no_results

      scope = filter_by_start_date(ConceptualExam, :classroom_id, :recorded_at)

      if discipline_ids.present?
        scope = scope.joins(:conceptual_exam_values)
                     .where(conceptual_exam_values: { discipline_id: discipline_ids })
      end

      scope.distinct
    end

    def recovery_diary_records
      return RecoveryDiaryRecord.none if @no_results

      filter_by_discipline(
        filter_by_start_date(RecoveryDiaryRecord, :classroom_id, :recorded_at)
      )
    end

    def discipline_content_records
      return DisciplineContentRecord.none if @no_results

      filter_by_discipline(
        filter_by_start_date_joined(
          DisciplineContentRecord.joins(:content_record),
          ContentRecord, :classroom_id, :record_date
        )
      )
    end

    def discipline_lesson_plans
      return DisciplineLessonPlan.none if @no_results

      filter_by_discipline(
        filter_by_start_date_joined(
          DisciplineLessonPlan.joins(:lesson_plan),
          LessonPlan, :classroom_id, :start_at
        )
      )
    end

    def discipline_teaching_plans
      return DisciplineTeachingPlan.none if @no_results

      scope = DisciplineTeachingPlan.joins(:teaching_plan)
                                    .where(teaching_plans: { year: @year })

      scope = scope.where(teaching_plans: { unity_id: @unity_ids }) if @unity_ids.present?
      scope = scope.where(teaching_plans: { grade_id: @grade_ids }) if @grade_ids.present?
      filter_by_discipline(scope)
    end

    def observation_diary_records
      return ObservationDiaryRecord.none if @no_results

      filter_by_discipline(
        filter_by_start_date(ObservationDiaryRecord, :classroom_id, :date)
      )
    end

    def transfer_notes
      return TransferNote.none if @no_results

      filter_by_discipline(
        filter_by_start_date(TransferNote, :classroom_id, :transfer_date)
      )
    end

    def complementary_exams
      return ComplementaryExam.none if @no_results

      filter_by_discipline(
        filter_by_start_date(ComplementaryExam, :classroom_id, :recorded_at)
      )
    end

    def descriptive_exams
      return DescriptiveExam.none if @no_results

      filter_by_discipline(
        filter_by_start_date(DescriptiveExam, :classroom_id, :recorded_at)
      )
    end

    def avaliation_exemptions
      return AvaliationExemption.none if @no_results

      scope = filter_by_start_date_joined(
        AvaliationExemption.joins(:avaliation),
        Avaliation, :classroom_id, :test_date
      )

      scope = scope.where(avaliations: { discipline_id: discipline_ids }) if discipline_ids.present?
      scope
    end

    private

    def filter_by_discipline(scope)
      discipline_ids.present? ? scope.where(discipline_id: discipline_ids) : scope
    end

    def filter_by_start_date(model, classroom_column, date_column)
      build_start_date_scope(model.arel_table, model.all, classroom_column, date_column)
    end

    def filter_by_start_date_joined(base_scope, joined_model, classroom_column, date_column)
      build_start_date_scope(joined_model.arel_table, base_scope, classroom_column, date_column)
    end

    def build_start_date_scope(arel, base_scope, classroom_column, date_column)
      return base_scope.none if classroom_start_dates.empty?

      conditions = classroom_start_dates.map do |start_date, ids|
        arel[classroom_column].in(ids).and(arel[date_column].gteq(start_date))
      end

      base_scope.where(conditions.inject(:or))
    end

    def classroom_start_dates
      @classroom_start_dates ||= resolve_classroom_start_dates
    end

    def resolve_classroom_start_dates
      dates, remaining_ids = classroom_calendar_start_dates
      school_calendar_start_dates(dates, remaining_ids) if remaining_ids.present?
      group_by_start_date(dates)
    end

    def classroom_calendar_start_dates
      dates = SchoolCalendarClassroomStep.joins(:school_calendar_classroom)
                                         .where(school_calendar_classrooms: { classroom_id: classroom_ids })
                                         .group('school_calendar_classrooms.classroom_id')
                                         .minimum(:start_at)

      [dates, classroom_ids - dates.keys]
    end

    def school_calendar_start_dates(dates, remaining_ids)
      classroom_unities = Classroom.where(id: remaining_ids).pluck(:id, :unity_id).to_h

      unity_dates = SchoolCalendarStep.joins(:school_calendar)
                                      .where(school_calendars: { unity_id: classroom_unities.values.uniq, year: @year })
                                      .group('school_calendars.unity_id')
                                      .minimum(:start_at)

      remaining_ids.each do |classroom_id|
        unity_date = unity_dates[classroom_unities[classroom_id]]
        dates[classroom_id] = unity_date if unity_date
      end
    end

    def group_by_start_date(dates)
      dates.each_with_object({}) do |(classroom_id, start_date), grouped|
        (grouped[start_date] ||= []) << classroom_id
      end
    end

    def resolve_ids
      @unity_ids = Unity.where(api_code: @unities).pluck(:id) if @unities.present?
      @course_ids = Course.where(api_code: @courses).pluck(:id) if @courses.present?

      resolve_grade_ids
      resolve_discipline_ids
      resolve_classroom_ids

      @no_results = any_filter_unresolved?
    end

    def any_filter_unresolved?
      (@unities.present? && @unity_ids.blank?) ||
        (@courses.present? && @course_ids.blank?) ||
        (@grades.present? && @grade_ids.blank?) ||
        (@disciplines.present? && @discipline_ids.blank?)
    end

    def resolve_grade_ids
      if @grades.present?
        @grade_ids = Grade.where(api_code: @grades)
        @grade_ids = @grade_ids.where(course_id: @course_ids) if @course_ids.present?
        @grade_ids = @grade_ids.pluck(:id)
      elsif @course_ids.present?
        @grade_ids = Grade.where(course_id: @course_ids).pluck(:id)
      end
    end

    def resolve_discipline_ids
      @discipline_ids = Discipline.where(api_code: @disciplines).pluck(:id) if @disciplines.present?
    end

    def resolve_classroom_ids
      if (@grades.present? || @courses.present?) && @grade_ids.blank?
        @classroom_ids = []
        return
      end

      scope = ClassroomsGrade.joins(:classroom)
                             .where(classrooms: { year: @year })

      scope = scope.where(grade_id: @grade_ids) if @grade_ids.present?
      scope = scope.where(classrooms: { unity_id: @unity_ids }) if @unity_ids.present?

      @classroom_ids = scope.pluck(:classroom_id).uniq
    end
  end
end
