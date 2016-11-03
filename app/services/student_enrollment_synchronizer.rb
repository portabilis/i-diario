class StudentEnrollmentSynchronizer

  def self.synchronize!(synchronization, year, unity_api_code)
    new(synchronization, year, unity_api_code).synchronize!
  end

  def initialize(synchronization, year, unity_api_code)
    self.synchronization = synchronization
    self.year = year
    self.unity_api_code = unity_api_code
  end

  def synchronize!
    update_records api.fetch(ano: year, escola: unity_api_code)["matriculas"]
  end

  protected

  attr_accessor :synchronization, :year, :unity_api_code

  def api
    IeducarApi::StudentEnrollments.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      if collection.present?
        collection.each do |record|
          if student_enrollment = student_enrollments.find_by(api_code: record["matricula_id"])
            update_existing_student_enrollment(record, student_enrollment)
          else
            create_new_student_enrollment(record)
          end
        end
      end
    end
  end

  def student_enrollments(klass = StudentEnrollment)
    klass
  end

  def student_enrollment_classrooms(klass = StudentEnrollmentClassroom)
    klass
  end

  def create_new_student_enrollment(record)
    student_enrollment = student_enrollments.create(
      api_code: record["matricula_id"],
      status: record["situacao"],
      student_id: Student.find_by(api_code: record["aluno_id"]).try(:id),
      student_code: record["aluno_id"],
      changed_at: record["data_atualizacao"].to_s,
      active: record["ativo"]
    )

    if record["enturmacoes"].present?
      record["enturmacoes"].each do |record_classroom|
        student_enrollment.student_enrollment_classrooms.create(
          api_code: record_classroom["sequencial"],
          classroom_id: Classroom.find_by(api_code: record_classroom["turma_id"]).try(:id),
          classroom_code: record_classroom["turma_id"],
          joined_at: record_classroom["data_entrada"],
          left_at: record_classroom["data_saida"],
          changed_at: record_classroom["data_atualizacao"].to_s,
          sequence: record_classroom["sequencial_fechamento"]
        )
      end
    end
  end

  def update_existing_student_enrollment(record, student_enrollment)
    if record["data_atualizacao"].to_s > student_enrollment.changed_at.to_s
      student_enrollment.update(
        status: record["situacao"],
        student_id: Student.find_by(api_code: record["aluno_id"]).try(:id),
        student_code: record["aluno_id"],
        changed_at: record["data_atualizacao"].to_s,
        active: record["ativo"]
      )
    end

    if record["enturmacoes"].present?
      any_updated_or_new_record = false
      record["enturmacoes"].each do |record_classroom|
        if student_enrollment_classroom = student_enrollment.student_enrollment_classrooms.find_by(api_code: record_classroom["sequencial"])
          any_updated_or_new_record = record_classroom["data_atualizacao"].to_s > student_enrollment_classroom.changed_at.to_s
          break if any_updated_or_new_record
        else
          any_updated_or_new_record = true
          break
        end
      end

      if any_updated_or_new_record
        student_enrollment.student_enrollment_classrooms.destroy_all
        record["enturmacoes"].each do |record_classroom|
          student_enrollment.student_enrollment_classrooms.create(
            api_code: record_classroom["sequencial"],
            classroom_id: Classroom.find_by(api_code: record_classroom["turma_id"]).try(:id),
            classroom_code: record_classroom["turma_id"],
            joined_at: record_classroom["data_entrada"],
            left_at: record_classroom["data_saida"],
            changed_at: record_classroom["data_atualizacao"].to_s,
            sequence: record_classroom["sequencial_fechamento"]
          )
        end
      else
        record["enturmacoes"].each do |record_classroom|
          if !student_enrollment.student_enrollment_classrooms.find_by(api_code: record_classroom["sequencial"])
            student_enrollment.student_enrollment_classrooms.create(
              api_code: record_classroom["sequencial"],
              classroom_id: Classroom.find_by(api_code: record_classroom["turma_id"]).try(:id),
              classroom_code: record_classroom["turma_id"],
              joined_at: record_classroom["data_entrada"],
              left_at: record_classroom["data_saida"],
              changed_at: record_classroom["data_atualizacao"].to_s,
              sequence: record_classroom["sequencial_fechamento"]
            )
          end
        end
      end
    end
  end
end
