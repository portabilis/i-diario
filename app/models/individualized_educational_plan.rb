class IndividualizedEducationalPlan < ApplicationRecord
  include Audit
  include Discardable
  include IepMultiSelectable

  # Campos apenas de exibição no formulário (prefill do i-Educar), não persistidos.
  attr_accessor :birth_date, :guardians, :guardians_unavailable, :diagnosis, :shift,
                :unity_name, :teacher_name, :classroom_name

  audited
  has_associated_audits

  belongs_to :student
  belongs_to :aee_teacher, class_name: 'Teacher'       # opcional

  has_many :iep_selected_options, dependent: :destroy

  # Ordem importa: o Rails destrói as associações na ordem de declaração das has_many.
  # Planejamentos/avaliações vêm ANTES de iep_review_dates para saírem primeiro — assim a
  # revisão é destruída sem filhos apontando pra ela (evita erro de FK e o guard da revisão).
  has_many :iep_curricular_plannings, dependent: :destroy
  has_many :iep_periodic_evaluations, dependent: :destroy
  has_many :iep_review_dates, dependent: :destroy

  # O snapshot imutável de cada versão publicada é o documento em si — o arquivamento preserva
  # essas linhas, e só um destroy real as leva junto.
  has_many :iep_versions, dependent: :destroy

  accepts_nested_attributes_for :iep_selected_options, allow_destroy: true

  # As 3 datas de revisão são exibidas por padrão, mas o preenchimento é opcional:
  # linhas novas em branco são descartadas (não viram registro nem disparam a validação de presença).
  accepts_nested_attributes_for :iep_review_dates, allow_destroy: true,
                                reject_if: ->(attrs) { attrs['id'].blank? && attrs['review_date'].blank? }

  # Linha nova (sem id) totalmente vazia é descartada. A régua de "vazio" é UMA só: o
  # empty_content? de cada model (o mesmo usado pelo prune de linhas salvas), evitando
  # manter duas listas de campos em sincronia — quem esquecer uma delas reintroduz o bug
  # de linha salva vazia travando/sumindo.
  accepts_nested_attributes_for :iep_curricular_plannings, allow_destroy: true,
    reject_if: ->(attrs) { attrs['id'].blank? && IepCurricularPlanning.new(attrs.except('id', '_destroy')).empty_content? }
  accepts_nested_attributes_for :iep_periodic_evaluations, allow_destroy: true,
    reject_if: ->(attrs) { attrs['id'].blank? && IepPeriodicEvaluation.new(attrs.except('id', '_destroy')).empty_content? }

  # Remove no save a linha já salva que foi esvaziada no formulário. Em before_validation
  # para rodar antes da validação abaixo, que precisa enxergar a linha já marcada como removida.
  # Fica de fora do arquivamento: ali o save grava só discarded_at, e a poda apagaria de vez a
  # linha de seção que o arquivamento existe para preservar.
  before_validation :prune_empty_section_lines, unless: :discarded_at_changed?

  # Bloqueia remover uma revisão que ainda tem conteúdo (não removido) nas seções 4/5.
  # Validado aqui (coleção em memória, já podada) para cobrir todas as revisões do submit
  # e preservar as demais edições do usuário ao exibir o erro.
  validate :prevent_removing_review_dates_in_use

  validates :elaborated_at, not_in_future: true
  validate :elaborated_at_within_year

  # Multi-selects das seções 2 e 3
  iep_multi_select :iep_selected_options,
                   :communication_profile, :social_interaction_profile, :autonomy,
                   :accompaniment, :support_type

  validates :student_id, :year, :elaborated_at, presence: true

  # Unicidade 1 PEI por aluno/ano, só entre os planos vivos: índice único parcial no banco + esta
  # validação para a mensagem amigável. Plano arquivado não ocupa o par aluno/ano.
  #
  # Consequência no undiscard: se já existe plano vivo para aquele aluno/ano, o save interno
  # reprova e undiscard devolve false SEM levantar — usar undiscard! para a falha não passar batida.
  validates :student_id, uniqueness: { scope: :year, conditions: -> { kept } }

  # Existe alguma versão ativa para este PEI? Usado pelos scopes finalized/draft.
  # SQL literal (não arel) para evitar o bind param que quebra o EXISTS no Rails 5.0.
  ACTIVE_VERSION_EXISTS_SQL =
    'EXISTS (SELECT 1 FROM iep_versions ' \
    'WHERE iep_versions.individualized_educational_plan_id = individualized_educational_plans.id ' \
    'AND iep_versions.active)'.freeze

  scope :finalized, -> { where(ACTIVE_VERSION_EXISTS_SQL) }
  scope :draft, -> { where("NOT #{ACTIVE_VERSION_EXISTS_SQL}") }
  # PEIs ligados à turma, para o filtro/cascata do index: aluno CURSANDO a turma hoje, ou turma que
  # publicou versão (autoria) — mesma regra do accessible_plans, só que restrita a uma turma. Sem o
  # attending_on, uma enturmação encerrada sem contribuição no PEI faria o aluno aparecer ao filtrar.
  scope :by_classroom_id, ->(classroom_id) {
    where(id: IepVersion.by_classroom(classroom_id).select(:individualized_educational_plan_id))
      .or(where(student_id: StudentEnrollmentClassroom.attending_student_ids(classroom_id)))
  }
  scope :by_student_id, ->(student_id) { where(student_id: student_id) }

  def finalized?
    active_version.present?
  end

  def active_version
    iep_versions.find_by(active: true)
  end

  private

  def elaborated_at_within_year
    return if elaborated_at.blank? || year.blank?
    # Mesma guarda do NotInFutureValidator: uma mensagem por campo, a primeira que couber.
    return if errors[:elaborated_at].any?
    return if elaborated_at.year == year.to_i

    errors.add(:elaborated_at, :not_in_plan_year, year: year)
  end

  def prune_empty_section_lines
    (iep_curricular_plannings + iep_periodic_evaluations).each do |line|
      line.mark_for_destruction if line.persisted? && !line.marked_for_destruction? && line.empty_content?
    end
  end

  # Usa a coleção em memória (já podada), não o banco, para enxergar linhas esvaziadas no mesmo submit.
  def prevent_removing_review_dates_in_use
    removed_reviews = iep_review_dates.select(&:marked_for_destruction?)
    return if removed_reviews.empty?

    review_ids_still_in_use = (iep_curricular_plannings + iep_periodic_evaluations)
                               .reject { |line| line.marked_for_destruction? || line.empty_content? }
                               .map(&:iep_review_date_id)

    removed_reviews.each do |review|
      next unless review_ids_still_in_use.include?(review.id)

      # Cancela a remoção bloqueada: sem isso o cocoon renderiza o link com classe
      # "destroyed" e o JS faz .hide() no carregamento — o input com erro fica invisível.
      review.instance_variable_set(:@marked_for_destruction, false)
      review.errors.add(:review_date, :cannot_remove)
      errors.add(:base, I18n.t('activerecord.errors.models.iep_review_date.in_use'))
    end
  end
end
