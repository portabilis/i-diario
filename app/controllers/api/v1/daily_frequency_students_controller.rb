# encoding: utf-8
class Api::V1::DailyFrequencyStudentsController < Api::V1::BaseController

  respond_to :json

  def update
    daily_frequency_student = DailyFrequencyStudent.find(params[:id])
    # the active: true is a workahound to fix https://sprint.ly/product/37978/item/876
    daily_frequency_student.update(present: params[:present], active: true)

    respond_with daily_frequency_student
  end

  def current_user
    User.find(user_id)
  end

  protected

  def user_id
    @user_id ||= params[:user_id] || 1
  end
end
