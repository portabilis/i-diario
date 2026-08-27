module Api
  # Os dias letivos de cada unidade, como conjunto de datas.
  #
  # Existe porque contar dias letivos e SABER QUAIS SÃO são coisas diferentes:
  # prazo em dias letivos, sequência de presenças e denominador de completude
  # só se calculam com o calendário na mão, e o que já se expunha era
  # fronteira de bimestre ou uma contagem.
  class UnitySchoolDaysService
    attr_reader :unities, :start_at, :end_at

    def self.call(unities:, start_at:, end_at:)
      new(unities: unities, start_at: start_at, end_at: end_at).call
    end

    def initialize(unities:, start_at:, end_at:)
      @unities = unities
      @start_at = start_at
      @end_at = end_at
    end

    def call
      school_days.group_by(&:first).map do |unity_api_code, rows|
        {
          unity_api_code: unity_api_code,
          school_days: rows.map { |row| row.last.to_s }
        }
      end
    end

    private

    def school_days
      UnitySchoolDay.joins(:unity)
                    .where(unity_id: unities.map(&:id))
                    .by_date_between(start_at, end_at)
                    .order(:school_day)
                    .pluck('unities.api_code', :school_day)
    end
  end
end
