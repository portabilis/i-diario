# encoding: utf-8
class Api::V2::DailyFrequencyStudentsController < Api::V2::BaseController

  respond_to :json

  def update
    daily_frequency_student = DailyFrequencyStudent.find(params[:id])
    # the active: true is a workahound to fix https://sprint.ly/product/37978/item/876
    daily_frequency_student.update(present: params[:present], active: true)

    respond_with daily_frequency_student
  end

  def update_or_create
    daily_frequency_student = nil

    creator = DailyFrequenciesCreator.new({
      unity: unity,
      classroom_id: params[:classroom_id],
      frequency_date: params[:frequency_date],
      class_number: params[:class_number],
      discipline_id: params[:discipline_id],
      school_calendar: current_school_calendar
    })
    creator.find_or_create!

    daily_frequency = creator.daily_frequencies[0]

    daily_frequency_student = DailyFrequencyStudent
                              .find_or_create_by(daily_frequency_id: daily_frequency.id,
                                                 student_id: params[:student_id],
                                                 active: true)

    daily_frequency_student.update(present: params[:present])

    respond_with daily_frequency_student
  end

  def current_user
    User.find(user_id)
  end

  protected

  def user_id
    @user_id ||= params[:user_id] || 1
  end

  def classroom
    @classroom ||= Classroom.find_by(id: params[:classroom_id])
  end

  def unity
    @unity ||= classroom.unity
  end

  def current_school_calendar
    @current_school_calendar ||= CurrentSchoolCalendarFetcher.new(unity, classroom).fetch
  end
end
