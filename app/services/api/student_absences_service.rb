module Api
  # Faltas lançadas por estudante, dia a dia, separando as que têm
  # justificativa vinculada das que não têm.
  #
  # Por que o retorno é por DIA e não um total: a justificativa nasce presa ao
  # lançamento, que é por aula quando a rede lança por componente. Um dia pode
  # ter três faltas e só uma justificada, e não cabe a este endpoint decidir se
  # esse dia conta como justificado — a régua é de quem lê. Aqui vai o fato:
  # quantos lançamentos de falta houve no dia e quantos deles têm vínculo.
  class StudentAbsencesService
    attr_reader :unity_api_code, :start_at, :end_at

    def self.call(unity_api_code:, start_at:, end_at:)
      new(unity_api_code: unity_api_code, start_at: start_at, end_at: end_at).call
    end

    def initialize(unity_api_code:, start_at:, end_at:)
      @unity_api_code = unity_api_code
      @start_at = start_at
      @end_at = end_at
    end

    def call
      rows.group_by { |row| row[0..2] }.map do |(student, classroom, unity), grouped|
        {
          student_api_code: student,
          classroom_api_code: classroom,
          unity_api_code: unity,
          absences: grouped.map { |row| day(row) }.sort_by { |absence| absence[:date] }
        }
      end
    end

    private

    # Uma consulta só: agrupa no banco e conta os vínculos de justificativa
    # (COUNT de coluna ignora nulo, que é exatamente a falta sem justificativa).
    def rows
      @rows ||= DailyFrequencyStudent.absences
                                     .joins(:student)
                                     .joins(daily_frequency: { classroom: :unity })
                                     .where(unities: { api_code: unity_api_code })
                                     .where(daily_frequencies: { frequency_date: start_at..end_at })
                                     .group(
                                       'students.api_code',
                                       'classrooms.api_code',
                                       'unities.api_code',
                                       'daily_frequencies.frequency_date'
                                     )
                                     .pluck(
                                       'students.api_code',
                                       'classrooms.api_code',
                                       'unities.api_code',
                                       'daily_frequencies.frequency_date',
                                       'COUNT(*)',
                                       'COUNT(daily_frequency_students.absence_justification_student_id)'
                                     )
    end

    def day(row)
      {
        date: row[3].to_s,
        entries_count: row[4],
        justified_entries_count: row[5]
      }
    end
  end
end
