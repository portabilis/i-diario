class TeachingPlanPolicy < ApplicationPolicy
  def edit?
    TeachingPlan.by_teacher_classroom_and_discipline(@user.current_teacher.id, @record.classroom_id, @record.discipline_id).any? { |teaching_plan| teaching_plan.id.eql?(@record.id) }
  end
end
