class DailyFrequencyStudentsController < ApplicationController
  respond_to :json

  def create_or_update
    daily_frequency_student = DailyFrequencyStudent.find_or_create_by(
      student_id: params[:student_id],
      daily_frequency_id: params[:daily_frequency_id]
    )
    daily_frequency_student.update({
      present: params[:present],
      dependence: params[:dependence]
    })

    respond_with daily_frequency_student
  end
end
