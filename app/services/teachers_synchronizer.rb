class TeachersSynchronizer
  def self.synchronize!(synchronization, year)
    new(synchronization, year).synchronize!
  end

  def initialize(synchronization, years)
    self.synchronization = synchronization
    self.years = years
  end

  def synchronize!
    years.each do |year|
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
      update_discipline_classrooms(collection, year)
    end
  end

  def update_discipline_classrooms(collection, year)
    existing_ids = []
    collection.each do |record|
      existing_ids << record['id']
      teacher = update_or_create_teacher(record)
      next unless teacher

      teacher_discipline_classrooms = discipline_classrooms.unscoped.where(
        api_code: record['id']
      )

      max_changed_at = teacher_discipline_classrooms.maximum(:changed_at)

      if !max_changed_at || record['updated_at'] > max_changed_at
        teacher_discipline_classrooms.destroy_all
        create_discipline_classrooms(record, year, teacher)
      end

      record['disciplinas_turmas'].each do |turma|
        next if turma['tipo_nota'].nil?
        tdc = TeacherDisciplineClassroom.find_by(teacher_api_code: record['servidor_id'],
                                         discipline_api_code: turma['disciplina_id'],
                                         api_code: record['id'])
        tdc.update!(score_type: turma['tipo_nota'])
      end
    end
  end

  private

  def destroy_inexisting_teacher_discipline_classrooms(existing_ids)
    discipline_classrooms.where.not(api_code: existing_ids).destroy_all
  end

  def create_discipline_classrooms(collection, year, teacher)
    collection['disciplinas_turmas'].each do |record|
      discipline_classrooms.create!(
        api_code: collection['id'],
        year: year,
        active: true,
        teacher_id: teacher.id,
        teacher_api_code: teacher.api_code,
        discipline_id: Discipline.find_by(api_code: record['disciplina_id']).try(:id),
        discipline_api_code: record['disciplina_id'],
        classroom_id: Classroom.find_by(api_code: record['turma_id']).try(:id),
        classroom_api_code: record['turma_id'],
        allow_absence_by_discipline: record['permite_lancar_faltas_componente'],
        changed_at: collection['updated_at']
      )
    end
  end

  def teachers(klass = Teacher)
    klass
  end

  def discipline_classrooms(klass = TeacherDisciplineClassroom)
    klass
  end

  def update_or_create_teacher(record)
    teacher = teachers.find_by(api_code: record['servidor_id'])
    if teacher
      teacher.update(name: record['name'])
    elsif record['name'].present?
      teacher = teachers.create!(
        api_code: record['servidor_id'],
        name: record['name']
      )
    end
    teacher
  end

  def inactive_all_alocations_prior_to(year)
    discipline_classrooms.unscoped.where('year < ?', year).destroy_all
  end
end
