class Api::V2::ContentRecordsController < Api::V2::BaseController
  respond_to :json

  def index
    return unless params[:teacher_id]
    @unities = Unity.by_teacher(params[:teacher_id]).ordered.uniq
    @number_of_days = params[:number_of_days] || 90

    @content_records = ContentRecord.by_unity_id(@unities.map(&:id))
                                    .by_teacher_id(params[:teacher_id])
                                    .joins(:discipline_content_record)
                                    .fromLastDays(@number_of_days)
                                    .includes(classroom: [:unity, :grade])

  end

  def lesson_plans
    @unities = Unity.by_teacher(params[:teacher_id]).ordered.uniq
    @number_of_days = params[:number_of_days] || 7

    @lesson_plans = LessonPlan.by_unity_id(@unities.map(&:id))
                           .by_teacher_id(params[:teacher_id])
                           .fromLastDays(@number_of_days)
                           .includes(classroom: [:unity, :grade])
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

    if discipline_id
      query = query.joins(:discipline_content_record)
                                        .where(discipline_content_records: { discipline_id: discipline_id } )
    elsif knowledge_areas
      query = query.joins(:knowledge_area_content_record)
                   .where(knowledge_area_content_records: { discipline_id: discipline_id } )
    end

    @content_record = query.first

    if !@content_record
      @content_record = ContentRecord.new
      @content_record.teacher_id = teacher_id
      @content_record.classroom_id = classroom_id
      @content_record.record_date = record_date
      if discipline_id
        @content_record.build_discipline_content_record(discipline_id: discipline_id)
      elsif knowledge_areas
        @content_record.build_knowledge_area_content_record(knowledge_areas: knowledge_areas)
      end
    end

    content_ids = []
    (contents||[]).each do |content|
      if content[:id].present?
        content_ids << content[:id]
      elsif
        content_ids << Content.find_or_create_by(description: content[:description]).id
      end
    end

    if content_ids.present?
      @content_record.content_ids = content_ids
      @content_record.save
    elsif @content_record.persisted?
      @content_record.destroy
    end
  end

end
