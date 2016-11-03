# encoding: utf-8
class Api::V1::DailyFrequencyStudentsController < Api::V1::BaseController

  respond_to :json

  def update
    user_id = params[:user_id] || 1

    Audited::Audit.as_user(User.find(user_id)) do
      daily_frequency_student = DailyFrequencyStudent.find(params[:id])
      daily_frequency_student.update(present: params[:present])
    end

    respond_with daily_frequency_student
  end
end
