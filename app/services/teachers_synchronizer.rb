class TeachersSynchronizer
  def self.synchronize!(synchronization)
    new(synchronization).synchronize!
  end

  def initialize(synchronization)
    self.synchronization = synchronization
  end

  def synchronize!
    update_records api.fetch(ano: Date.today.year)["servidores"]
  end

  protected

  attr_accessor :synchronization

  def api
    IeducarApi::Teachers.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |record|
        teacher = nil

        if teacher = teachers.find_by(api_code: record["id"])
          teacher.update(name: record["name"])
        elsif record["name"].present?
          teacher = teachers.create!(
            api_code: record["id"],
            name: record["name"]
          )
        end
        update_discipline_classrooms(record['disciplinas_turmas'], teacher)
      end
    end
  end

  def update_discipline_classrooms(collection, teacher)
    year = Date.today.year

    if teacher.present?
      Sidekiq.logger.info teacher.inspect
      # inactivate all records and activate when find
      teacher.teacher_discipline_classrooms.update_all(active: false)

      collection.each do |record|

        if discipline_classroom = discipline_classrooms.unscoped.where(teacher_api_code: teacher.api_code,
                                                                      discipline_api_code: record['disciplina_id'],
                                                                      classroom_api_code: record['turma_id']).first
          discipline_classroom.update_attribute(:active, true)
        else
          discipline_classrooms.create!(
            year: year,
            active: true,
            teacher_id: teacher.id,
            teacher_api_code: teacher.api_code,
            discipline_id: Discipline.find_by(api_code: record['disciplina_id']),
            discipline_api_code: record['disciplina_id'],
            classroom_id: Classroom.find_by(api_code: record['turma_id']),
            classroom_api_code: record['turma_id']
          )
        end
      end
    end
  end

  def teachers(klass = Teacher)
    klass
  end

  def discipline_classrooms(klass = TeacherDisciplineClassroom)
    klass
  end
end
