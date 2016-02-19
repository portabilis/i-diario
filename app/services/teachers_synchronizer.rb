class TeachersSynchronizer
  def self.synchronize!(synchronization, year)
    new(synchronization, year).synchronize!
  end

  def initialize(synchronization, year)
    self.synchronization = synchronization
    self.year = year
  end

  def synchronize!
    update_records api.fetch(ano: year)["servidores"]
  end

  protected

  attr_accessor :synchronization, :year

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
    if teacher.present?

      inactivate_all_teacher_information(teacher, year)

      collection.each do |record|

        discipline_classroom = discipline_classrooms.unscoped.where(teacher_api_code: teacher.api_code,
                                                                    discipline_api_code: record['disciplina_id'],
                                                                    classroom_api_code: record['turma_id'],
                                                                    year: year).first

        next if !discipline_classroom

        discipline = Discipline.find_by(api_code: discipline_classroom.discipline_api_code)
        classroom = Classroom.find_by(api_code: discipline_classroom.classroom_api_code)

        current_calendar_year = school_calendar_fetcher.new(classroom.unity_id).fetch.try(:year)

        if discipline_classroom.year == current_calendar_year
          if discipline_classroom
            discipline_classroom.update_attributes(
              active: true,
              discipline_id: discipline.try(:id),
              classroom_id: classroom.try(:id)
            )
          else
            discipline_classrooms.create!(
              year: year,
              active: true,
              teacher_id: teacher.id,
              teacher_api_code: teacher.api_code,
              discipline_id: discipline.try(:id),
              discipline_api_code: record['disciplina_id'],
              classroom_id: classroom.try(:id),
              classroom_api_code: record['turma_id']
            )
          end
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

  def school_calendar_fetcher(klass = CurrentSchoolCalendarFetcher)
    klass
  end

  def inactivate_all_teacher_information(teacher, year)
    teacher.teacher_discipline_classrooms.where(year: year).update_all(active: false)
  end

end
