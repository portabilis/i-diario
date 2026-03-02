# frozen_string_literal: true

module Api
  # Counts discipline records by type for preview before deletion
  class DisciplineRecordsCounter
    RECORD_TYPES = %i[
      daily_frequencies avaliations conceptual_exams recovery_diary_records
      discipline_content_records discipline_lesson_plans discipline_teaching_plans
      observation_diary_records transfer_notes complementary_exams avaliation_exemptions
    ].freeze

    LABELS = {
      daily_frequencies: 'Frequências diárias',
      avaliations: 'Avaliações numéricas',
      conceptual_exams: 'Avaliações conceituais',
      recovery_diary_records: 'Recuperações',
      discipline_content_records: 'Registros de conteúdo',
      discipline_lesson_plans: 'Planos de aula',
      discipline_teaching_plans: 'Planos de ensino',
      observation_diary_records: 'Diários de observação',
      transfer_notes: 'Notas de transferência',
      complementary_exams: 'Exames complementares',
      avaliation_exemptions: 'Dispensas de avaliação'
    }.freeze

    def initialize(unities:, courses:, grades:, disciplines:, year:)
      @query = DisciplineRecordsQuery.new(
        unities: unities, courses: courses, grades: grades,
        disciplines: disciplines, year: year
      )
    end

    def call
      RECORD_TYPES.map do |type|
        { label: LABELS[type], count: @query.public_send(type).count }
      end
    end
  end
end
