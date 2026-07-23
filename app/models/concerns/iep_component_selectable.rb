# Uma linha das seções 4/5 do PEI é preenchida "Por Disciplina" (discipline)
# OU "Por Campo de Experiência" (knowledge_area) — exatamente um dos dois.
module IepComponentSelectable
  extend ActiveSupport::Concern

  included do
    belongs_to :discipline
    belongs_to :knowledge_area

    validate :discipline_or_knowledge_area
    validate :review_date_belongs_to_plan

    # Um componente (disciplina ou campo de experiência) só pode aparecer uma vez por revisão.
    # Trava server-side espelhada por índice único no banco — o client já filtra, mas
    # double-submit/request forjada passariam por cima.
    validates :discipline_id, uniqueness: { scope: :iep_review_date_id }, allow_nil: true
    validates :knowledge_area_id, uniqueness: { scope: :iep_review_date_id }, allow_nil: true
  end

  private

  def discipline_or_knowledge_area
    return if discipline_id.present? ^ knowledge_area_id.present?

    errors.add(:base, :component_or_experience_required)
  end

  # A revisão vinculada tem que ser do mesmo plano. O iep_review_date_id vem de um hidden
  # manipulável e a FK só garante que a revisão existe, não que pertence a este plano —
  # sem isso, dava para vincular a linha a uma revisão de outro plano da mesma Entity.
  def review_date_belongs_to_plan
    return if iep_review_date_id.blank? || individualized_educational_plan_id.blank?
    return if iep_review_date&.individualized_educational_plan_id == individualized_educational_plan_id

    errors.add(:iep_review_date_id, :invalid)
  end
end
