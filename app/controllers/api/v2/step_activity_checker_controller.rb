module Api
  module V2
    class StepActivityCheckerController < Api::V2::IeducarApiBaseController
      respond_to :json

      def index
        step_number = params[:step_number].to_i

        has_activity = if params[:unity_id].present?
                         unity_id = Unity.find_by(api_code: params[:unity_id]).id

                         check_by_unity(unity_id, step_number)
                       else
                         @classroom = Classroom.find_by(api_code: params[:classroom_id])

                         check_by_classroom(@classroom.id, step_number)
                       end

        render json: has_activity
      end

      private

      def check_by_unity(unity_id, step_number)
        calendar_step = school_calendar_step(unity_id, step_number)

        daily_frequencies = frequencies_in_step(
          calendar_step.school_calendar_id,
          calendar_step.start_at,
          calendar_step.end_at
        ).by_unity_id(unity_id)

        return true if daily_frequencies.any?

        avaliations = Avaliation.by_unity_id(unity_id)
                                .by_school_calendar_step(calendar_step.id)
                                .limit(1)

        return true if avaliations.any?

        false
      end

      def check_by_classroom(classroom_id, step_number)
        calendar_step = school_classroom_calendar_step(step_number)

        daily_frequencies = frequencies_in_step(
          calendar_step.school_calendar_id,
          calendar_step.start_at,
          calendar_step.end_at
        ).by_classroom_id(classroom_id)

        return true if daily_frequencies.any?

        avaliations = Avaliation.by_classroom_id(classroom_id)
                                .by_school_calendar_classroom_step(calendar_step.id)
                                .limit(1)

        return true if avaliations.any?

        false
      end

      def school_calendar_step(unity_id, step_number)
        year = CurrentSchoolYearFetcher.new(unity_id).fetch

        SchoolCalendarStep.by_unity(unity_id)
                          .by_year(year)
                          .by_step_number(step_number)
                          .first
      end

      def school_classroom_calendar_step(step_number)
        StepsFetcher.new(@classroom).step(step_number)
      end

      def frequencies_in_step(school_calendar_id, start_at, end_at)
        DailyFrequency.by_school_calendar_id(school_calendar_id)
                      .by_frequency_date_between(start_at, end_at)
                      .limit(1)
      end
    end
  end
end
