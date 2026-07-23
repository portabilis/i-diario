class IepReviewDate < ApplicationRecord
  audited associated_with: :iep

  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id

  has_many :iep_curricular_plannings
  has_many :iep_periodic_evaluations

  validates :review_date, presence: true

  before_destroy :prevent_destroy_if_filled, prepend: true

  private

  # Impede remover uma revisão isolada que ainda tem conteúdo nas seções 4/5 apontando pra ela.
  # Quando a remoção parte do plano (exclusão em cascata, ou conteúdo removido no mesmo save),
  # a regra é validada no plano (IndividualizedEducationalPlan#prevent_removing_review_dates_in_use);
  # aqui destroyed_by_association ou o EXISTS já limpo liberam a exclusão.
  def prevent_destroy_if_filled
    return if destroyed_by_association
    return unless iep_curricular_plannings.exists? || iep_periodic_evaluations.exists?

    errors.add(:base, I18n.t('activerecord.errors.models.iep_review_date.in_use'))
    throw(:abort)
  end
end
