module Api
  class ActivityAfterDepartureDate
    def initialize(student_id, departure_date)
      @student_id = student_id
      @departure_date = departure_date
    end

    def has_activities
      # return i18n.t '' if DailyFrequency.where(classroom_id: @classrooms_ids, discipline_id: @discipline_id).pluck(:id)

      # return true if Avaliation.where(classroom_id: @classrooms_ids, discipline_id: @discipline_id).exists?
      
      # false
    end
  end
end
