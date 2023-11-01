class CreateAbsenceJustificationsService
  include Pundit

  def self.call(*params)
    new(*params).call
  end

  def initialize(class_numbers, params, teacher, unity, school_calendar, user)
    @class_numbers = class_numbers
    @params = params
    @teacher = teacher
    @unity = unity
    @school_calendar = school_calendar
    @user = user
  end

  def call
    [
      frequency_by_discipline?,
      absence_justifications,
      @absence_justification
    ]
  end

  def absence_justifications
    class_numbers.map do |class_number|
      @absence_justification = build_absence_justification(class_number)
      @absence_justification.tap(&:save)
    end
  end

  def build_absence_justification(class_number)
    AbsenceJustification.new(params) do |absence_justification|
      absence_justification.class_number = class_number
      absence_justification.teacher = teacher
      absence_justification.user = user
      absence_justification.unity = unity
      absence_justification.school_calendar = school_calendar
    end
  end

  def frequency_by_discipline?
    classroom = Classroom.find_by(id: params[:classroom_id])

    frequency_type_definer = FrequencyTypeDefiner.new(
      classroom,
      teacher
    )
    frequency_type_definer.define!

    frequency_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE
  end

  attr_reader :class_numbers, :teacher, :params, :user, :unity, :school_calendar
end
