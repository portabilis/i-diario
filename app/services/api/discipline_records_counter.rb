# frozen_string_literal: true

module Api
  # Counts discipline records by type for preview before deletion
  class DisciplineRecordsCounter
    RECORD_TYPES = %i[
      daily_frequencies avaliations conceptual_exams recovery_diary_records
      discipline_content_records discipline_lesson_plans discipline_teaching_plans
      observation_diary_records transfer_notes complementary_exams descriptive_exams
    ].freeze

    def initialize(unities:, courses:, grades:, disciplines:, year:)
      @query = DisciplineRecordsQuery.new(
        unities: unities, courses: courses, grades: grades,
        disciplines: disciplines, year: year
      )
    end

    def call
      RECORD_TYPES.map do |type|
        { label: label_for(type), count: @query.public_send(type).count }
      end
    end

    private

    def label_for(type)
      key = type == :recovery_diary_records ? :recovery_diary_records_menu : type
      I18n.t("navigation.#{key}")
    end
  end
end
