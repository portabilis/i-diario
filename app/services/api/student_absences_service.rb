module Api
  # Dias de falta por estudante, dizendo quantos lançamentos daquele dia têm
  # justificativa vinculada.
  #
  # O DIA vem da consolidação diária — a mesma fonte que alimenta o motor de
  # infrequência —, e não da soma dos lançamentos por aula. É o que mantém a
  # contagem coerente com as notificações que o gestor recebe no i-Diário: se o
  # dia consolidou como presente, ele não aparece aqui, mesmo que exista falta
  # numa aula isolada.
  #
  # A justificativa, essa só existe no lançamento (a consolidação guarda apenas
  # presente/ausente), então ela é buscada no diário e devolvida como contagem
  # do dia. Quando um dia tem três faltas lançadas e só uma justificada, o fato
  # vai cru: decidir se esse dia conta como justificado é régua de quem lê.
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
      consolidated_days.group_by { |row| row[0..2] }.map do |(student, classroom, unity), days|
        {
          student_api_code: student,
          classroom_api_code: classroom,
          unity_api_code: unity,
          absences: days.map { |row| day(row) }.sort_by { |absence| absence[:date] }
        }
      end
    end

    private

    # Os dias que a consolidação marcou como falta, no recorte pedido.
    def consolidated_days
      @consolidated_days ||=
        UniqueDailyFrequencyStudent.where(present: false)
                                   .joins(:student)
                                   .joins(classroom: :unity)
                                   .where(unities: { api_code: unity_api_code })
                                   .where(frequency_date: start_at..end_at)
                                   .pluck(
                                     'students.api_code',
                                     'classrooms.api_code',
                                     'unities.api_code',
                                     :frequency_date,
                                     :student_id,
                                     :classroom_id
                                   )
    end

    def day(row)
      chave = [row[4], row[5], row[3]]

      {
        date: row[3].to_s,
        entries_count: entries.fetch(chave, [0, 0])[0],
        justified_entries_count: entries.fetch(chave, [0, 0])[1]
      }
    end

    # Os lançamentos de falta do diário, contados de uma vez para todo o
    # recorte: COUNT da coluna de justificativa ignora nulo, que é exatamente
    # a falta sem vínculo.
    def entries
      @entries ||=
        DailyFrequencyStudent.absences
                             .joins(daily_frequency: { classroom: :unity })
                             .where(unities: { api_code: unity_api_code })
                             .where(daily_frequencies: { frequency_date: start_at..end_at })
                             .group(
                               'daily_frequency_students.student_id',
                               'daily_frequencies.classroom_id',
                               'daily_frequencies.frequency_date'
                             )
                             .pluck(
                               'daily_frequency_students.student_id',
                               'daily_frequencies.classroom_id',
                               'daily_frequencies.frequency_date',
                               'COUNT(*)',
                               'COUNT(daily_frequency_students.absence_justification_student_id)'
                             )
                             .each_with_object({}) do |(student_id, classroom_id, date, total, justified), mapa|
                               mapa[[student_id, classroom_id, date]] = [total, justified]
                             end
    end
  end
end
