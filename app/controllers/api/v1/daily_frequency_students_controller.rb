# encoding: utf-8
class Api::V1::DailyFrequencyStudentsController < Api::V1::BaseController

  respond_to :json

  def update
    daily_frequency_student = DailyFrequencyStudent.find(params[:id])
    daily_frequency_student.update(present: params[:present])

    respond_with daily_frequency_student
  end
end
