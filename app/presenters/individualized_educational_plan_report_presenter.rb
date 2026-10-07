# Apresenta o PEI para visualização/PDF a partir da estrutura canônica do snapshot —
# tanto para o plano vivo (from_record) quanto para uma versão publicada (from_snapshot),
# garantindo a mesma renderização nos dois casos.
class IndividualizedEducationalPlanReportPresenter
  def initialize(content)
    @content = content.to_h
  end

  def self.from_record(plan, classroom: nil)
    new(IndividualizedEducationalPlanSnapshot.build(plan, classroom: classroom))
  end

  def self.from_snapshot(content)
    new(content)
  end

  def identification
    section('identification')
  end

  def characterization
    section('characterization')
  end

  def support_team
    section('support_team')
  end

  def final_evaluation
    section('final_evaluation')
  end

  def medications
    IndividualizedEducationalPlanSnapshot.medications_from(support_team)
  end

  # Linhas das seções 4/5 agrupadas por revisão (1ª, 2ª...), com os componentes em
  # ordem alfabética dentro de cada revisão (ordenação determinística).
  def curricular_plannings_by_review
    lines_by_review('curricular_plannings')
  end

  def periodic_evaluations_by_review
    lines_by_review('periodic_evaluations')
  end

  # Campo preenchido? (string, array ou valor simples)
  def filled?(value)
    value.respond_to?(:reject) ? value.reject(&:blank?).any? : value.present?
  end

  def any_filled?(hash, keys)
    keys.any? { |key| filled?(hash[key]) }
  end

  # Formata SÓ valores de data para exibição: Date (plano vivo, from_record) ou string
  # ISO (snapshot da versão, from_snapshot). Não parseia texto arbitrário — escola/turma/
  # responsáveis não são datas. Erro esperado (string não-ISO) cai no valor original.
  def localized_date(value)
    return value if value.blank?
    return I18n.l(value) if value.is_a?(Date)

    I18n.l(Date.iso8601(value.to_s))
  rescue ArgumentError
    value
  end

  private

  attr_reader :content

  def section(key)
    content[key].to_h
  end

  def lines_by_review(key)
    Array(content[key])
      .group_by { |line| [line['review_number'].to_i, line['review_date']] }
      .sort_by(&:first)
      .map { |review, lines| [review, lines.sort_by { |line| line['component_name'].to_s }] }
  end
end
