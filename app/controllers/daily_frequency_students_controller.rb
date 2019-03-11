class DailyFrequencyStudentsController < ApplicationController
  respond_to :json

  def create_or_update
    daily_frequency_student = begin
                                DailyFrequencyStudent.find_or_create_by(
                                  student_id: params[:student_id],
                                  daily_frequency_id: params[:daily_frequency_id]
                                )
                              rescue ActiveRecord::RecordNotUnique
                                retry
                              end

    daily_frequency_student.update(
      active: true,
      present: params[:present],
      dependence: params[:dependence]
    )

    respond_with daily_frequency_student
  end
end
