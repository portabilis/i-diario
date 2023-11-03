class CheckTypeFrequencyByDisciplineService
  def self.call(*params)
    new(*params).call
  end

  def initialize(classroom_id, teacher_id)
    @classroom_id = classroom_id
    @teacher_id = teacher_id
  end

  def call
    return if classroom_id.blank? || teacher.blank?

    classroom = Classroom.find_by(id: classroom_id)

    frequency_type_definer = FrequencyTypeDefiner.new(
      classroom,
      teacher_id
    )
    frequency_type_definer.define!

    frequency_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE
  end

  attr_reader :classroom_id, :teacher
end
