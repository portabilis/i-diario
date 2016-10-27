class StudentEnrollmentDependenceSynchronizer

  def self.synchronize!(synchronization, year)
    new(synchronization, year).synchronize!
  end

  def initialize(synchronization, year)
    self.synchronization = synchronization
    self.year = year
  end

  def synchronize!
    destroy_records
    create_records api.fetch(ano: year)["dependencias"]
  end

  protected

  attr_accessor :synchronization, :year

  def api
    IeducarApi::StudentEnrollmentDependences.new(synchronization.to_api)
  end

  def create_records(collection)

    ActiveRecord::Base.transaction do
      if collection.present?
        collection.each do |record|
          student_enrollment_dependences.create(
            student_enrollment_id: student_enrollments.find_by(api_code: record['matricula_id']).try(:id),
            student_enrollment_code: record['matricula_id'],
            discipline_id: disciplines.find_by(api_code: record['disciplina_id']).try(:id),
            discipline_code: record['disciplina_id']
          )
        end
      end
    end
  end

  def destroy_records
    student_enrollment_dependences.destroy_all
  end

  def student_enrollment_dependences(klass = StudentEnrollmentDependence)
    klass
  end

  def disciplines(klass = Discipline)
    klass
  end

  def student_enrollments(klass = StudentEnrollment)
    klass
  end
end
