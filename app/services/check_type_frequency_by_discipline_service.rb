class CheckTypeFrequencyByDisciplineService
  def self.call(*params)
    new(*params).call
  end

  def initialize(classroom_id, teacher_id)
    @classroom_id = classroom_id
    @teacher_id = teacher_id
  end

  def call
    return if classroom_id.blank? || teacher_id.blank?

    classroom = Classroom.find_by(id: classroom_id)

    FrequencyTypeDefiner.allow_frequency_by_discipline?(
      classroom,
      teacher_id
    )
  end

  attr_reader :classroom_id, :teacher_id
end
