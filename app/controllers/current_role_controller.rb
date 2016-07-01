# encoding: utf-8
class CurrentRoleController < ApplicationController
  def index
    @user_roles = current_user.user_roles
  end

  def set

    case access_level
    when AccessLevel::TEACHER
      # raise "a"
    end

    if current_user.set_current_user_role!(user_role.try(:id), user_teacher.try(:id))
      redirect_to root_path, notice: I18n.t('.current_role.set.notice')
    else
      redirect_to root_path, alert: I18n.t('.current_role.set.alert')
    end
  end

  private

  def user_role
    @user_role ||= UserRole.find(params[:user][:current_user_role_id])
  end

  def user_unity
    @user_unity ||= Unity.find(params[:user][:current_user_unity_id])
  end

  def user_classroom
    @user_classroom ||= Classroom.find(params[:user][:current_user_classroom_id])
  end

  def user_discipline
    @user_discipline ||= Discipline.find(params[:user][:current_user_discipline_id])
  end

  def user_teacher
    @user_teacher ||= Teacher.find(params[:user][:teacher_id])
  end

  def access_level
    @access_level ||= user_role.role.access_level
  end
end
