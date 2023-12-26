module Api
  module V2
    class DailyFrequencyStudentsController < Api::V2::BaseController
      respond_to :json

      def update
        daily_frequency_student = DailyFrequencyStudent.find(params[:id])
        daily_frequency_student.update(present: params[:present], active: true)

        respond_with daily_frequency_student
      end

      def update_or_create
        creator = DailyFrequenciesCreator.new(
          unity: unity,
          classroom_id: params[:classroom_id],
          frequency_date: params[:frequency_date],
          class_numbers: [params[:class_number]],
          discipline_id: params[:discipline_id],
          school_calendar: current_school_calendar,
          period: period
        )
        creator.find_or_create!

        frequency_date = params[:frequency_date]
        student_id = params[:student_id]

        daily_frequency = creator.daily_frequencies[0]

        absence_justifications = AbsenceJustifiedOnDate.call(
          students: [params[:student_id]],
          date: frequency_date,
          end_date: frequency_date,
          classroom: params[:classroom_id],
          period: period
        )

        if daily_frequency
          begin
            daily_frequency_student = DailyFrequencyStudent.find_or_initialize_by(
              daily_frequency_id: daily_frequency.id,
              student_id: student_id
            )

            absence_justification = absence_justifications[student_id] || {}
            absence_justification = absence_justification[frequency_date] || {}
            absence_justification_student_id = absence_justification[0] || absence_justification[daily_frequency.class_number]

            if absence_justification_student_id
              daily_frequency_student.present = false
              daily_frequency_student.absence_justification_student_id = absence_justification_student_id
            elsif
              daily_frequency_student.present = params[:present]
            end

            daily_frequency_student.active = true
            daily_frequency_student.save
          rescue ActiveRecord::RecordNotUnique
            retry
          end

          UniqueDailyFrequencyStudentsCreator.call_worker(
            current_entity.id,
            daily_frequency.classroom_id,
            daily_frequency.frequency_date,
            current_teacher_id
          )

          respond_with daily_frequency_student
        else
          render json: []
        end
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
