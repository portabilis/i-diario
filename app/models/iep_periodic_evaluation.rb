class IepPeriodicEvaluation < ApplicationRecord
  include IepComponentSelectable

  audited associated_with: :iep

  # touch: mantém o updated_at do plano (coluna "Última edição" do index) atualizado
  # quando o usuário edita só a seção 5, sem mexer em colunas do próprio plano.
  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id, touch: true
  belongs_to :iep_review_date                          # revisão (1ª, 2ª...) a que a avaliação pertence

  validates :iep_review_date_id, presence: true

  # Sem nenhum conteúdo preenchido — usado para remover a linha quando o usuário
  # esvazia o formulário do componente.
  def empty_content?
    acquired_skills.blank? && in_progress_skills.blank? && not_acquired_skills.blank? &&
      period_report.blank? && next_stage_adjustments.blank?
  end
end
