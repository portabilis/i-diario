class DisciplinesController < ApplicationController
  respond_to :json

  has_scope :by_unity_id
  has_scope :by_grade
  has_scope :by_classroom

  def index
    return unless current_teacher.present?

    if params[:classroom_id].present?
      params[:by_classroom] = params[:classroom_id]
    end

    @disciplines = apply_scopes(Discipline).by_teacher_id(current_teacher.id)
      .ordered
  end
end
