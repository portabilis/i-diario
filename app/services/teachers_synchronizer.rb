class TeachersSynchronizer
  def self.synchronize!(synchronization, year)
    new(synchronization, year).synchronize!
  end

  def initialize(synchronization, years)
    self.synchronization = synchronization
    self.years = years
  end

  def synchronize!

    inactive_all_alocations_prior_to(years[0]) if years.any?

    years.each do |year|
      inactivate_all_allocations_for(year)
      update_records(api.fetch(ano: year)['servidores'], year)
    end
  end

  protected

  attr_accessor :synchronization, :years

  def api
    IeducarApi::Teachers.new(synchronization.to_api)
  end

  def update_records(collection, year)
    ActiveRecord::Base.transaction do

      collection.each do |record|
        teacher = update_or_create_teacher(record)
        update_discipline_classrooms(record['disciplinas_turmas'], teacher, year)
      end
    end
  end

  def update_discipline_classrooms(collection, teacher, year)
    return unless teacher

    # inactivate all records and activate when find
    # teacher.teacher_discipline_classrooms.update_all(active: false)

    collection.each do |record|

      if discipline_classroom = discipline_classrooms.unscoped.where(teacher_api_code: teacher.api_code,
                                                                    discipline_api_code: record['disciplina_id'],
                                                                    classroom_api_code: record['turma_id'],
                                                                    year: year,
                                                                    allow_absence_by_discipline: record['permite_lancar_faltas_componente']).first
        discipline_classroom.update_attributes(
          active: true,
          discipline_id: Discipline.find_by(api_code: discipline_classroom.discipline_api_code).try(:id),
          classroom_id: Classroom.find_by(api_code: discipline_classroom.classroom_api_code).try(:id),
          allow_absence_by_discipline: record['permite_lancar_faltas_componente']
        )
      else
        discipline_classrooms.create!(
          year: year,
          active: true,
          teacher_id: teacher.id,
          teacher_api_code: teacher.api_code,
          discipline_id: Discipline.find_by(api_code: record['disciplina_id']).try(:id),
          discipline_api_code: record['disciplina_id'],
          classroom_id: Classroom.find_by(api_code: record['turma_id']).try(:id),
          classroom_api_code: record['turma_id'],
          allow_absence_by_discipline: record['permite_lancar_faltas_componente']
        )
      end
    end
  end

  def clear_inactive_teacher_allocations_from_users(teacher)
    users_allocated = User.where(teacher_id: teacher)
    users_assumed = User.where(assumed_teacher_id: teacher)
    users = users_allocated + users_assumed

    users.each do |user|
      classroom = user.current_classroom

      has_teacher_allocation = discipline_classrooms.where(classroom_id: classroom, active: true, year: year).any?

      if !has_teacher_allocation
        user.clear_allocation
      end
    end

  end

  def teachers(klass = Teacher)
    klass
  end

  def discipline_classrooms(klass = TeacherDisciplineClassroom)
    klass
  end

  private

  def update_or_create_teacher(record)
    teacher = teachers.find_by(api_code: record['id'])
    if teacher
      teacher.update(name: record['name'])
    elsif record['name'].present?
      teacher = teachers.create!(
        api_code: record['id'],
        name: record['name']
      )
    end
    teacher
  end

  def inactivate_all_allocations_for(year)
    discipline_classrooms.where(year: year).update_all(active: false)
  end

  def inactive_all_alocations_prior_to(year)
    discipline_classrooms.where('year < ?', year).update_all(active: false)
  end
end
