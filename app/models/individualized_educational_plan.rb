class IndividualizedEducationalPlan < ApplicationRecord
  include Audit
  include IepMultiSelectable

  # Campos apenas de exibição no formulário (prefill do i-Educar), não persistidos.
  attr_accessor :birth_date, :guardians, :diagnosis, :shift, :unity_name, :teacher_name

  audited
  has_associated_audits

  belongs_to :student
  belongs_to :unity
  belongs_to :classroom
  belongs_to :teacher                                  # professor regente (único, da turma)
  belongs_to :aee_teacher, class_name: 'Teacher'       # opcional

  has_many :iep_review_dates, dependent: :destroy
  has_many :iep_attachments, dependent: :destroy
  has_many :iep_selected_options, dependent: :destroy
  has_many :iep_curricular_plannings, dependent: :destroy
  has_many :iep_periodic_evaluations, dependent: :destroy
  has_many :iep_versions, dependent: :destroy

  accepts_nested_attributes_for :iep_review_dates, :iep_attachments, :iep_selected_options,
                                :iep_curricular_plannings, :iep_periodic_evaluations,
                                allow_destroy: true

  # Multi-selects das seções 2 e 3
  iep_multi_select :iep_selected_options,
                   :communication_profile, :social_interaction_profile, :autonomy,
                   :accompaniment, :support_type

  validates :student_id, :unity_id, :classroom_id, :teacher_id, :year, :elaborated_at,
            presence: true

  # Unicidade 1 PEI por aluno/ano: índice único no banco + esta validação para a mensagem amigável.
  validates :student_id, uniqueness: { scope: :year }

  # Existe alguma versão ativa para este PEI? Usado pelos scopes finalized/draft.
  # SQL literal (não arel) para evitar o bind param que quebra o EXISTS no Rails 5.0.
  ACTIVE_VERSION_EXISTS_SQL =
    'EXISTS (SELECT 1 FROM iep_versions ' \
    'WHERE iep_versions.individualized_educational_plan_id = individualized_educational_plans.id ' \
    'AND iep_versions.active)'.freeze

  scope :finalized, -> { where(ACTIVE_VERSION_EXISTS_SQL) }
  scope :draft, -> { where("NOT #{ACTIVE_VERSION_EXISTS_SQL}") }
  scope :by_classroom_id, ->(classroom_id) { where(classroom_id: classroom_id) }
  scope :by_student_id, ->(student_id) { where(student_id: student_id) }

  def finalized?
    active_version.present?
  end

  def active_version
    iep_versions.find_by(active: true)
  end
end
