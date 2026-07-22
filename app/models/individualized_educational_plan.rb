class IndividualizedEducationalPlan < ApplicationRecord
  include Audit
  include IepMultiSelectable

  # Campos apenas de exibição no formulário (prefill do i-Educar), não persistidos.
  attr_accessor :birth_date, :guardians, :diagnosis, :shift, :unity_name, :teacher_name, :classroom_name

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

  accepts_nested_attributes_for :iep_attachments, :iep_selected_options, allow_destroy: true

  # As 3 datas de revisão são exibidas por padrão, mas o preenchimento é opcional:
  # linhas novas em branco são descartadas (não viram registro nem disparam a validação de presença).
  accepts_nested_attributes_for :iep_review_dates, allow_destroy: true,
                                reject_if: ->(attrs) { attrs['id'].blank? && attrs['review_date'].blank? }

  # Campos que caracterizam "conteúdo preenchido" nas seções 4 e 5 — a régua para
  # não criar linha nova vazia (reject_if) e para remover linha salva que foi esvaziada (prune).
  SECTION4_CONTENT_FIELDS = %w[
    long_term_goal stage_objectives skills_to_develop methodologies
    instructional_accommodation_option_ids environmental_accommodation_option_ids
    assessment_accommodation_option_ids
  ].freeze
  SECTION5_CONTENT_FIELDS = %w[
    acquired_skills in_progress_skills not_acquired_skills period_report next_stage_adjustments
  ].freeze

  accepts_nested_attributes_for :iep_curricular_plannings, allow_destroy: true,
    reject_if: ->(attrs) { attrs['id'].blank? && SECTION4_CONTENT_FIELDS.all? { |field| attrs[field].blank? } }
  accepts_nested_attributes_for :iep_periodic_evaluations, allow_destroy: true,
    reject_if: ->(attrs) { attrs['id'].blank? && SECTION5_CONTENT_FIELDS.all? { |field| attrs[field].blank? } }

  # Linha já salva cujo formulário foi esvaziado é removida no save — sem isso a
  # revisão vinculada ficaria bloqueada para remoção mesmo depois de limpar os campos.
  before_save :prune_empty_section_lines

  # Multi-selects das seções 2 e 3
  iep_multi_select :iep_selected_options,
                   :communication_profile, :social_interaction_profile, :autonomy,
                   :accompaniment, :support_type

  validates :student_id, :unity_id, :classroom_id, :year, :elaborated_at,
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

  private

  def prune_empty_section_lines
    (iep_curricular_plannings + iep_periodic_evaluations).each do |line|
      line.mark_for_destruction if line.persisted? && !line.marked_for_destruction? && line.empty_content?
    end
  end
end
