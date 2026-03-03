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

    def start_date
      @start_date ||= Date.new(@year, 1, 1)
    end

    def daily_frequencies
      filter_by_discipline(
        DailyFrequency.where(classroom_id: classroom_ids)
                      .where('frequency_date >= ?', start_date)
      )
    end

    def avaliations
      filter_by_discipline(
        Avaliation.where(classroom_id: classroom_ids)
                  .where('test_date >= ?', start_date)
      )
    end

    def conceptual_exams
      scope = ConceptualExam.where(classroom_id: classroom_ids)
                            .where('recorded_at >= ?', start_date)

      if discipline_ids.present?
        scope = scope.joins(:conceptual_exam_values)
                     .where(conceptual_exam_values: { discipline_id: discipline_ids })
      end

      scope.distinct
    end

    def recovery_diary_records
      filter_by_discipline(
        RecoveryDiaryRecord.where(classroom_id: classroom_ids)
                           .where('recorded_at >= ?', start_date)
      )
    end

    def discipline_content_records
      filter_by_discipline(
        DisciplineContentRecord.joins(:content_record)
                               .where(content_records: { classroom_id: classroom_ids })
                               .where('content_records.record_date >= ?', start_date)
      )
    end

    def discipline_lesson_plans
      filter_by_discipline(
        DisciplineLessonPlan.joins(:lesson_plan)
                            .where(lesson_plans: { classroom_id: classroom_ids })
                            .where('lesson_plans.start_at >= ?', start_date)
      )
    end

    def discipline_teaching_plans
      scope = DisciplineTeachingPlan.joins(:teaching_plan)
                                    .where(teaching_plans: { year: @year })

      scope = scope.where(teaching_plans: { unity_id: @unity_ids }) if @unity_ids.present?
      scope = scope.where(teaching_plans: { grade_id: @grade_ids }) if @grade_ids.present?
      filter_by_discipline(scope)
    end

    def observation_diary_records
      filter_by_discipline(
        ObservationDiaryRecord.where(classroom_id: classroom_ids)
                              .where('date >= ?', start_date)
      )
    end

    def transfer_notes
      filter_by_discipline(
        TransferNote.where(classroom_id: classroom_ids)
                    .where('transfer_date >= ?', start_date)
      )
    end

    def complementary_exams
      filter_by_discipline(
        ComplementaryExam.where(classroom_id: classroom_ids)
                         .where('recorded_at >= ?', start_date)
      )
    end

    def avaliation_exemptions
      scope = AvaliationExemption.joins(:avaliation)
                                 .where(avaliations: { classroom_id: classroom_ids })
                                 .where('avaliations.test_date >= ?', start_date)

      scope = scope.where(avaliations: { discipline_id: discipline_ids }) if discipline_ids.present?
      scope
    end

    private

    def filter_by_discipline(scope)
      discipline_ids.present? ? scope.where(discipline_id: discipline_ids) : scope
    end

    def resolve_ids
      @unity_ids = Unity.where(api_code: @unities).pluck(:id) if @unities.present?
      @course_ids = Course.where(api_code: @courses).pluck(:id) if @courses.present?

      resolve_grade_ids
      resolve_discipline_ids
      resolve_classroom_ids
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
      scope = ClassroomsGrade.joins(:classroom)
                             .where(classrooms: { year: @year })

      scope = scope.where(grade_id: @grade_ids) if @grade_ids.present?
      scope = scope.where(classrooms: { unity_id: @unity_ids }) if @unity_ids.present?

      @classroom_ids = scope.pluck(:classroom_id).uniq
    end
  end
end
