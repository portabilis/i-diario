class DisciplineLessonPlanClonerForm
  include ActiveModel::Model

  attr_accessor :classroom_ids, :discipline_lesson_plan_id

  validates :discipline_lesson_plan_id, :classroom_ids, presence: true

  def clone!
    if valid?
      begin
        ActiveRecord::Base.transaction do
          Classroom.where(id: classroom_ids).each do |classroom|
            new_lesson_plan = discipline_lesson_plan.dup
            new_lesson_plan.lesson_plan = discipline_lesson_plan.lesson_plan.dup
            new_lesson_plan.lesson_plan.contents = discipline_lesson_plan.lesson_plan.contents
            new_lesson_plan.lesson_plan.classroom = classroom
            new_lesson_plan.save!
          end
          return true
        end
      rescue ActiveRecord::RecordInvalid => e
        message = e.to_s
        message.slice!("A validação falhou: ")
        errors.add(:classroom_ids, message)
        return false
      end
    end
  end

  def discipline_lesson_plan
    @discipline_lesson_plan ||= DisciplineLessonPlan.find(discipline_lesson_plan_id)
  end
end
