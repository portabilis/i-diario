module Api
  module V2
    class DailyFrequencyStudentsController < Api::V2::BaseController
      respond_to :json

      def update
        daily_frequency_student = DailyFrequencyStudent.find(params[:id])
        updated = daily_frequency_student.update(
          present: params[:present],
          active: daily_frequency_student.enrolled_in_classroom?
        )

        daily_frequency = daily_frequency_student.daily_frequency

        # Este endpoint não recebe o professor; o dono do diário responde pelo envio. A coluna é
        # nullable: diário sem dono não tem envio automático, e o enqueuer registra isso no log.
        if updated
          AutomaticAbsencePostingEnqueuer.call(
            entity_id: current_entity.id,
            classroom_id: daily_frequency.classroom_id,
            frequency_dates: [daily_frequency.frequency_date],
            teacher_id: daily_frequency.owner_teacher_id
          )
        end

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

        if daily_frequency
          existing_justification = AbsenceJustificationPreserver.call(
            frequency_date: frequency_date,
            classroom_id: params[:classroom_id],
            period: period,
            class_number: params[:class_number] || 0,
            student_ids: [student_id]
          )

          begin
            daily_frequency_student = DailyFrequencyStudent.find_or_initialize_by(
              daily_frequency_id: daily_frequency.id,
              student_id: student_id
            )

            absence_justification_student_id = existing_justification[student_id]

            if absence_justification_student_id
              daily_frequency_student.present = false
              daily_frequency_student.absence_justification_student_id = absence_justification_student_id
            else
              daily_frequency_student.present = params[:present]
            end

            # Antes de salvar busca o real status do aluno na turma, caso ele tenha saído
            # da turma, o registro de frequência deve ser inativo
            daily_frequency_student.active = daily_frequency_student.enrolled_in_classroom?
            daily_frequency_student.save
          rescue ActiveRecord::RecordNotUnique
            retry
          end

          UniqueDailyFrequencyStudentsCreator.call_worker(
            current_entity.id,
            daily_frequency.classroom_id,
            daily_frequency.frequency_date,
            current_teacher_id || current_user.teacher_id
          )

          AutomaticAbsencePostingEnqueuer.call(
            entity_id: current_entity.id,
            classroom_id: daily_frequency.classroom_id,
            frequency_dates: [daily_frequency.frequency_date],
            teacher_id: current_teacher_id || current_user.teacher_id
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
        @classroom ||= Classroom.find(params[:classroom_id])
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
