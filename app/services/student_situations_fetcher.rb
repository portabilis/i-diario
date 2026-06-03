# Calcula, em lote, as situações dos alunos (dependência, dispensa, ativo na data e busca ativa)
# a partir de uma lista de enrollment_ids.

class StudentSituationsFetcher
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @enrollment_ids = params.fetch(:enrollment_ids)
    @classroom = params.fetch(:classroom)
    @discipline = params.fetch(:discipline)
    @step_number = params.fetch(:step_number, nil)
    @date = params.fetch(:date)
  end

  def call
    return empty_result if @enrollment_ids.blank?

    date = @date.to_date

    {
      dependencies: StudentsInDependency.call(
        student_enrollments: @enrollment_ids,
        disciplines: @discipline
      ),
      exemptions: fetch_exemptions,
      active_on_date_ids: fetch_active_on_date_ids(date),
      enrollments_in_active_search:
        ActiveSearch.new.enrollments_in_active_search?(@enrollment_ids, date)[date] || []
    }
  end

  private

  def fetch_exemptions
    return {} unless @step_number && @discipline

    StudentsExemptFromDiscipline.call(
      student_enrollments: @enrollment_ids,
      discipline: @discipline,
      step: @step_number,
      classroom_id: @classroom.id
    )
  end

  def fetch_active_on_date_ids(date)
    StudentEnrollment.where(id: @enrollment_ids)
                     .by_classroom(@classroom)
                     .by_date(date)
                     .pluck(:id)
                     .to_set
  end

  def empty_result
    {
      dependencies: {},
      exemptions: {},
      active_on_date_ids: Set.new,
      enrollments_in_active_search: []
    }
  end
end
