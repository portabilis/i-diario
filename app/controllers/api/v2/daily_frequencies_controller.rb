module Api
  module V2
    class DailyFrequenciesController < Api::V2::BaseController
      respond_to :json

      def index
        frequency_type_resolver = FrequencyTypeResolver.new(classroom, teacher)
        general_frequency = frequency_type_resolver.general?

        @daily_frequencies = DailyFrequency.by_classroom_id(params[:classroom_id]).by_period(period)
        @daily_frequencies = @daily_frequencies.general_frequency if general_frequency
        @daily_frequencies = @daily_frequencies.by_discipline_id(params[:discipline_id]) unless general_frequency

        @daily_frequencies = @daily_frequencies.order_by_frequency_date_desc
                                               .order_by_unity
                                               .order_by_classroom
                                               .order_by_class_number
                                               .includes(:unity, :classroom, :discipline, :students)

        respond_with @daily_frequencies
      end

      def create
        classes = params[:class_number] || (params[:class_numbers] && params[:class_numbers].split(','))
        @class_numbers = Array(classes)
        @class_numbers = [nil] if @class_numbers.blank?

        creator = DailyFrequenciesCreator.new(frequency_params)
        creator.find_or_create!

        if params[:class_numbers].present?
          render json: creator.daily_frequencies
        else
          render json: creator.daily_frequencies[0]
        end
      end

      def current_user
        @current_user ||= User.find(user_id)
      end

      private

      def frequency_params
        {
          unity_id: unity.id,
          classroom_id: classroom.id,
          discipline_id: params[:discipline_id],
          frequency_date: params[:frequency_date],
          class_numbers: @class_numbers,
          school_calendar: current_school_calendar,
          period: period
        }
      end

      def teacher
        @teacher ||= Teacher.find_by(id: params[:teacher_id])
      end

      def configuration
        @configuration ||= IeducarApiConfiguration.current
      end

      def current_school_calendar
        @current_school_calendar ||= CurrentSchoolCalendarFetcher.new(unity, classroom).fetch
      end

      def classroom
        @classroom ||= Classroom.find_by(id: params[:classroom_id])
      end

      def unity
        @unity ||= classroom.unity
      end

      def user_id
        @user_id ||= params[:user_id] || 1
      end

      def period
        TeacherPeriodFetcher.new(
          params['teacher_id'],
          params['classroom_id'],
          params['discipline_id']
        ).teacher_period
      end
    end
  end
end
