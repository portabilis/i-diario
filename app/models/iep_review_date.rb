class IepReviewDate < ApplicationRecord
  audited associated_with: :iep

  # touch: mantém o updated_at do plano (coluna "Última edição" do index) atualizado
  # ao adicionar/remover uma data de revisão sem mexer em colunas do próprio plano.
  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id, touch: true

  has_many :iep_curricular_plannings
  has_many :iep_periodic_evaluations

  validates :review_date, presence: true

  before_destroy :prevent_destroy_if_filled, prepend: true

  private

  # Regra de negócio: a revisão não pode ser removida quando o período já tem
  # informações preenchidas nas seções 4 (planejamento) e/ou 5 (avaliação).
  def prevent_destroy_if_filled
    return unless iep_curricular_plannings.exists? || iep_periodic_evaluations.exists?

    errors.add(:base, I18n.t('activerecord.errors.models.iep_review_date.in_use'))
    throw(:abort)
  end
end
