class ContentPolicy < ApplicationPolicy
  def edit?
    Content.by_teacher_classroom_and_discipline(@user.teacher.id, @record.classroom_id, @record.discipline_id).any? { |content| content.id.eql?(@record.id) }
  end
end