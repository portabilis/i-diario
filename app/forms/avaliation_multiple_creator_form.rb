class AvaliationMultipleCreatorForm
  include ActiveModel::Model
  include I18n::Alchemy

  # A coluna Turma resume o que só aquela turma explica: vínculo do professor com a turma ou com a
  # disciplina, série sem a disciplina na grade, e o peso e o tipo de avaliação ainda disponíveis
  # na etapa, que dependem do que já foi lançado naquela turma. Data e Série ficam de fora porque
  # têm campo na própria linha, e os campos do topo porque o formulário já os valida.
  CLASSROOM_ROW_ERROR_ATTRIBUTES = %i[classroom_id discipline_id grades weight test_setting_test].freeze

  attr_accessor :test_setting_id, :unity_id, :discipline_id, :test_setting_test_id,
                :description, :weight, :observations, :school_calendar_id, :avaliations, :teacher_id

  validates :unity_id,             presence: true
  validates :discipline_id,        presence: true
  validates :school_calendar_id,   presence: true
  validates :test_setting_id,      presence: true
  validates :test_setting_test_id, presence: true, if: :sum_calculation_type?
  validates :description,       presence: true, if: -> { !sum_calculation_type? || allow_break_up? }
  validates :weight,            presence: true, if: :should_validate_weight?
  validate :at_least_one_assigned_avaliation

  def initialize(attributes = {})
    @teacher_id = attributes[:teacher_id]
    @avaliations = []
    super
  end

  # Os dois lados precisam rodar: o && curto-circuitaria a checagem por turma sempre que um campo
  # do topo estivesse inválido, e a linha da turma ficaria sem apontar o próprio erro.
  def valid?
    form_valid = super
    avaliations_valid = add_avaliations_errors_to_classrooms

    form_valid && avaliations_valid
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      avaliations.select(&:include).each(&:save!)
      self
    end
  end

  def test_setting
    return if test_setting_id.blank?

    @test_setting ||= TestSetting.find(test_setting_id)
  end

  def unity
    return if unity_id.blank?

    @unity ||= Unity.find(unity_id)
  end

  def discipline
    return if discipline_id.blank?

    @discipline ||= Discipline.find(discipline_id)
  end

  def test_setting_test
    return if test_setting_test_id.blank?

    @test_setting_test ||= TestSettingTest.find(test_setting_test_id)
  end

  def school_calendar
    SchoolCalendar.find_by(id: school_calendar_id)
  end

  def avaliations_attributes=(avaliations)
    return unless avaliations.present?

    @avaliations = []

    avaliations.each do |avaliation_attributes|
      classroom_id = avaliation_attributes.last['classroom_id'].to_i
      avaliation = Avaliation.new.localized

      avaliation.assign_attributes(
        include: avaliation_attributes.last['include'] == '1',
        classroom_id: classroom_id,
        test_date: avaliation_attributes.last['test_date'],
        classes: avaliation_attributes.last['classes'],
        test_setting_id: self.test_setting_id,
        discipline_id: self.discipline_id,
        test_setting_test_id: self.test_setting_test_id,
        description: self.description,
        weight: self.weight,
        observations: self.observations,
        school_calendar_id: self.school_calendar_id,
        teacher_id: teacher_id,
        grade_ids: avaliation_attributes.last['grade_ids']&.split(','),
        should_create_recovery: avaliation_attributes.last['should_create_recovery'] == '1'
      )

      @avaliations << avaliation
    end
  end

  def load_avaliations!(teacher_id, school_calendar_year)
    return unless discipline_id.present? && teacher_id.present?

    classrooms = Classroom.by_unity_and_teacher(unity_id, teacher_id)
                          .by_teacher_discipline(discipline_id)
                          .by_year(school_calendar_year)
                          .ordered

    @avaliations = []

    classrooms.each do |classroom|
      @avaliations << Avaliation.new(classroom_id: classroom.id)
    end
  end

  protected

  def at_least_one_assigned_avaliation
    errors.add(:avaliations, :at_least_one_assigned_avaliation) if avaliations.select(&:include).blank?
  end

  def allow_break_up?
    test_setting_test&.allow_break_up
  end

  def average_calculation_type
    return '' if test_setting.nil?

    test_setting.average_calculation_type
  end

  def sum_calculation_type?
    average_calculation_type == 'sum'
  end

  def arithmetic_and_sum_calculation_type?
    average_calculation_type == 'arithmetic_and_sum'
  end

  def should_validate_weight?
    allow_break_up? || arithmetic_and_sum_calculation_type?
  end

  def add_avaliations_errors_to_classrooms
    valid = true

    avaliations.select(&:include).each do |avaliation|
      grade_present = avaliation.grade_ids.present?

      next if grade_present && avaliation.valid?

      error_message = avaliation_error(avaliation)

      unless grade_present
        avaliation.errors.add(:grade_ids, I18n.t('errors.messages.blank'))
      end

      if error_message
        errors.add(:base, error_message)
        avaliation.errors.add(:classroom, error_message)
      end

      valid = false
    end

    valid
  end

  private

  # A mensagem que já saiu num campo do topo não se repete na linha: sobra para a linha o que só
  # aquela turma explica.
  def avaliation_error(avaliation)
    attributes = avaliation.errors.keys & CLASSROOM_ROW_ERROR_ATTRIBUTES
    messages = attributes.flat_map { |attribute| avaliation.errors.full_messages_for(attribute) }

    (messages - form_field_messages).first
  end

  # O :base acumula a mensagem de cada turma já processada — comparar com ele apagaria a mensagem
  # da segunda turma em diante.
  def form_field_messages
    (errors.keys - [:base]).flat_map { |attribute| errors.full_messages_for(attribute) }
  end
end
