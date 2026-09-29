class IndividualizedEducationalPlan < ApplicationRecord
  include Audit
  include Discardable
  include IepMultiSelectable

  # Campos apenas de exibição no formulário (prefill do i-Educar), não persistidos.
  attr_accessor :birth_date, :guardians, :guardians_unavailable, :diagnosis, :shift,
                :unity_name, :teacher_name, :classroom_name

  # Substituídas por iep_medications; saem do schema numa migration posterior, depois que
  # nenhum processo em execução ainda as leia.
  self.ignored_columns = %w[medication_name medication_dosage medication_schedule]

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

  # Ordem de cadastro: é a ordem exibida no formulário, no PDF e na versão publicada.
  has_many :iep_medications, -> { order(:id) }, dependent: :destroy,
           foreign_key: :individualized_educational_plan_id, inverse_of: :iep

  # O snapshot imutável de cada versão publicada é o documento em si — o arquivamento preserva
  # essas linhas, e só um destroy real as leva junto.
  has_many :iep_versions, dependent: :destroy

  accepts_nested_attributes_for :iep_selected_options, allow_destroy: true

  # As 3 datas de revisão são exibidas por padrão, mas o preenchimento é opcional:
  # linhas novas em branco são descartadas (não viram registro nem disparam a validação de presença).
  accepts_nested_attributes_for :iep_review_dates, allow_destroy: true,
                                reject_if: ->(attrs) { attrs['id'].blank? && attrs['review_date'].blank? }

  # Linha nova totalmente vazia (a que o formulário insere ao responder "Sim") é descartada.
  accepts_nested_attributes_for :iep_medications, allow_destroy: true,
                                reject_if: ->(attrs) { attrs['id'].blank? && attrs.except('_destroy').values.all?(&:blank?) }

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

  # Medicamento só existe com "Sim": com "Não" ou sem resposta as linhas são removidas no save,
  # inclusive as que o formulário apenas escondeu. Fora do arquivamento pelo mesmo motivo da poda acima.
  before_validation :discard_medications_unless_used, unless: :discarded_at_changed?

  # Bloqueia remover uma revisão que ainda tem conteúdo (não removido) nas seções 4/5.
  # Validado aqui (coleção em memória, já podada) para cobrir todas as revisões do submit
  # e preservar as demais edições do usuário ao exibir o erro.
  validate :prevent_removing_review_dates_in_use

  # Só quando a seção de medicação foi mexida: o professor salva o plano inteiro sem poder editar
  # a seção 3, e um "Sim" antigo sem medicamento não pode travar o salvamento dele.
  validate :medication_required_when_used, if: :medication_changed?

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

  def discard_medications_unless_used
    return if uses_medication

    iep_medications.each(&:mark_for_destruction)
  end

  def medication_changed?
    uses_medication_changed? || iep_medications.any?(&:changed_for_autosave?)
  end

  def medication_required_when_used
    return unless uses_medication

    live_medications = iep_medications.reject(&:marked_for_destruction?)
    return if live_medications.any? { |medication| medication.name.present? }

    # Em :base porque o erro aparece no topo do formulário, visível em qualquer etapa do wizard.
    errors.add(:base, I18n.t('activerecord.errors.models.individualized_educational_plan.medication_required'))
    highlight_missing_medication_name(live_medications)
  end

  # Marca o nome da primeira linha para o formulário destacar o campo e abrir a etapa 3. Sem linha
  # (a vazia é descartada pelo reject_if), constrói uma: o save já falhou, então ela não é gravada.
  # O autosave valida as linhas antes deste validate, por isso o erro é adicionado aqui.
  def highlight_missing_medication_name(live_medications)
    medication = live_medications.first || iep_medications.build
    medication.errors.add(:name, :blank) if medication.errors[:name].empty?
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
