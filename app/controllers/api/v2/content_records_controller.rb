module Api
  module V2
    class ContentRecordsController < Api::V2::BaseController
      respond_to :json

      def index
        return unless params[:teacher_id]

        @unities = Unity.by_teacher(params[:teacher_id]).ordered.uniq
        @number_of_days = params[:number_of_days] ? params[:number_of_days].to_i : 90

        @content_records = ContentRecord.by_unity_id(@unities.map(&:id))
                                        .by_teacher_id(params[:teacher_id])
                                        .joins(:discipline_content_record)
                                        .fromLastDays(@number_of_days)
                                        .includes(classroom: [:unity, classrooms_grades: :grade])
      end

      def lesson_plans
        @unities = Unity.by_teacher(params[:teacher_id]).ordered.uniq
        @number_of_days = params[:number_of_days] || 7

        @lesson_plans = LessonPlan.by_unity_id(@unities.map(&:id))
                                  .by_teacher_id(params[:teacher_id])
                                  .fromLastDays(@number_of_days)
                                  .includes(classroom: [:unity, classrooms_grades: :grade])
                                  .ordered
      end

      def sync
        contents = params[:contents]
        classroom_id = params[:classroom_id]
        teacher_id = params[:teacher_id]
        record_date = params[:record_date]
        discipline_id = params[:discipline_id]
        knowledge_areas = params[:knowledge_areas]

        query = ContentRecord.where(teacher_id: teacher_id, classroom_id: classroom_id, record_date: record_date)

        @content_record =
          if discipline_id
            query.joins(:discipline_content_record)
                 .find_by(discipline_content_records: { discipline_id: discipline_id })
          elsif knowledge_areas
            query.joins(:knowledge_area_content_record)
                 .find_by(knowledge_area_content_records: { discipline_id: discipline_id })
          end

        unless @content_record
          @content_record = ContentRecord.new
          @content_record.teacher = Teacher.find(teacher_id)
          @content_record.classroom_id = classroom_id
          @content_record.record_date = record_date
          @content_record.origin = OriginTypes::API_V2

          if discipline_id
            @content_record.build_discipline_content_record(
              discipline_id: discipline_id,
              teacher_id: teacher_id
            )
          elsif knowledge_areas
            @content_record.build_knowledge_area_content_record(
              knowledge_areas: knowledge_areas,
              teacher_id: teacher_id
            )
          end
        end

        @content_record.not_validate_columns = true

        content_ids = []

        (contents || []).each do |content|
          content_id = content[:id]
          content_id ||= Content.find_or_create_by(description: content[:description]).id

          content_ids << content_id if content_id.present?
        end

        user = User.find_by_teacher_id(teacher_id)

        Audited.audit_class.as_user(user) do
          if content_ids.present?
            @content_record.content_ids = content_ids
            @content_record.save
          elsif @content_record.persisted?
            @content_record.destroy
          end
        end

        true
      end
    end
  end
end
