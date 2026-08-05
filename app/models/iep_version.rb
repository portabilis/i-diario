class IepVersion < ApplicationRecord
  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id
  belongs_to :published_by, class_name: 'User'
  belongs_to :classroom # turma que publicou a versão (autoria); nulo nas versões legadas

  validates :name, :published_at, presence: true
  validates :name, length: { minimum: 3 }, allow_blank: true
  # Autoria obrigatória: a visibilidade e o congelamento do PEI dependem da turma que publicou a
  # versão. on: :create porque o classroom_id é definido no publish e nunca muda depois.
  validates :classroom_id, presence: true, on: :create

  scope :recent_first, -> { order(published_at: :desc) }
  scope :current, -> { where(active: true) }   # versão vigente ("Ativo")
  scope :by_classroom, ->(classroom_ids) { where(classroom_id: classroom_ids) } # versões que aquelas turmas publicaram
end
