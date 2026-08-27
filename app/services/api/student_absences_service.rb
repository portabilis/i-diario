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
    attr_reader :unities, :start_at, :end_at

    def self.call(unities:, start_at:, end_at:)
      new(unities: unities, start_at: start_at, end_at: end_at).call
    end

    def initialize(unities:, start_at:, end_at:)
      @unities = unities
      @start_at = start_at
      @end_at = end_at
    end

    # O agrupamento é pelos IDS, não pelos api_codes: estudante cadastrado
    # localmente não tem api_code, e dois deles na mesma turma colapsariam numa
    # entrada só, com as faltas somadas.
    def call
      consolidated_days.group_by { |row| [row[4], row[5]] }.map do |_ids, days|
        {
          student_api_code: days.first[0],
          classroom_api_code: days.first[1],
          unity_api_code: days.first[2],
          absences: days.map { |row| day(row) }.sort_by { |absence| absence[:date] }
        }
      end
    end

    private

    def unity_ids
      @unity_ids ||= unities.map(&:id)
    end

    # Os dias que a consolidação marcou como falta, no recorte pedido.
    def consolidated_days
      @consolidated_days ||=
        UniqueDailyFrequencyStudent.where(present: false)
                                   .joins(:student)
                                   .joins(classroom: :unity)
                                   .where(classrooms: { unity_id: unity_ids })
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
      key = [row[4], row[5], row[3]]

      {
        date: row[3].to_s,
        entries_count: entries.fetch(key, [0, 0])[0],
        justified_entries_count: entries.fetch(key, [0, 0])[1]
      }
    end

    # Os lançamentos de falta do diário, contados de uma vez para todo o
    # recorte. Só os lançamentos ativos, como faz a consolidação: aluno que
    # saiu da turma fica com `present` nulo no lançamento, e `absences` o
    # contaria como falta. COUNT da coluna de justificativa ignora nulo, que é
    # exatamente a falta sem vínculo.
    def entries
      @entries ||=
        DailyFrequencyStudent.active
                             .absences
                             .joins(daily_frequency: :classroom)
                             .where(classrooms: { unity_id: unity_ids })
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
                             .each_with_object({}) do |(student_id, classroom_id, date, total, justified), map|
                               map[[student_id, classroom_id, date]] = [total, justified]
                             end
    end
  end
end
