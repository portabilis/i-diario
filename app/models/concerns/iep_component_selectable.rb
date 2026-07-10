# Uma linha das seções 4/5 do PEI é preenchida "Por Disciplina" (discipline)
# OU "Por Campo de Experiência" (knowledge_area) — exatamente um dos dois.
module IepComponentSelectable
  extend ActiveSupport::Concern

  included do
    belongs_to :discipline
    belongs_to :knowledge_area

    validate :discipline_or_knowledge_area
  end

  private

  def discipline_or_knowledge_area
    return if discipline_id.present? ^ knowledge_area_id.present?

    errors.add(:base, :component_or_experience_required)
  end
end
