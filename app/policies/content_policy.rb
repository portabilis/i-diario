class ContentPolicy < ApplicationPolicy
  def edit?
    contents = Content.by_unity_id(@user.current_user_role.unity.id)
      .by_teacher_id(@user.current_teacher.id)

    contents.any? { |content| content.id.eql?(@record.id) }
  end
end
