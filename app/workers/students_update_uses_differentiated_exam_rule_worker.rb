class StudentsUpdateUsesDifferentiatedExamRuleWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(params)
    params = params.with_indifferent_access

    Entity.find(params[:entity_id]).using_connection do
      perform_by_deficiency_id(params[:deficiency_id]) if params[:deficiency_id].present?

      return if params[:student_id].blank?

      student = Student.with_discarded.find(params[:student_id])

      perform_by_student(student)
    end
  end

  private

  def perform_by_deficiency_id(deficiency_id)
    all_deficiency_students(deficiency_id).each do |deficiency_student|
      perform_by_student(deficiency_student.student)
    end
  end

  def perform_by_student(student)
    student.uses_differentiated_exam_rule = uses_differentiated_exam_rule(student)
    student.save! if student.changed?
  end

  def uses_differentiated_exam_rule(student)
    student.deficiencies.where(deficiencies: { disconsider_differentiated_exam_rule: false }).exists?
  end

  def all_deficiency_students(deficiency_id)
    DeficiencyStudent.with_discarded.by_deficiency_id(deficiency_id)
  end
end
