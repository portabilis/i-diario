class KnowledgeAreaContentRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher

  def index
    @knowledge_area_content_records = apply_scopes(KnowledgeAreaContentRecord)
      .includes(:knowledge_areas, content_record: [:classroom])
      .by_unity_id(current_user_unity.id)
      .by_teacher_id(current_teacher.id)

    authorize @knowledge_area_content_records
  end

  def new
    @knowledge_area_content_record = KnowledgeAreaContentRecord.new.localized
    @knowledge_area_content_record.build_content_record(
      record_date: Time.zone.now,
      unity_id: current_user_unity.id
    )

    authorize @knowledge_area_content_record
  end

  def create
    @knowledge_area_content_record = KnowledgeAreaContentRecord.new(resource_params).localized
    @knowledge_area_content_record.knowledge_area_ids = resource_params[:knowledge_area_ids].split(',')
    @knowledge_area_content_record.content_record.teacher = current_teacher

    @knowledge_area_content_record.content_record.content_ids = content_ids

    authorize @knowledge_area_content_record

    if @knowledge_area_content_record.save
      respond_with @knowledge_area_content_record, location: knowledge_area_content_records_path
    else
      render :new
    end
  end

  def edit
    @knowledge_area_content_record = KnowledgeAreaContentRecord.find(params[:id]).localized

    authorize @knowledge_area_content_record
  end

  def update
    @knowledge_area_content_record = KnowledgeAreaContentRecord.find(params[:id]).localized
    @knowledge_area_content_record.assign_attributes(resource_params)

    @knowledge_area_content_record.content_record.content_ids = content_ids

    authorize @knowledge_area_content_record

    if @knowledge_area_content_record.save
      respond_with @knowledge_area_content_record, location: knowledge_area_content_records_path
    else
      render :edit
    end
  end

  def destroy
    @knowledge_area_content_record = KnowledgeAreaContentRecord.find(params[:id]).localized

    authorize @knowledge_area_content_record

    @knowledge_area_content_record.destroy

    respond_with @knowledge_area_content_record, location: knowledge_area_content_records_path
  end

  def history
    @knowledge_area_content_record = KnowledgeAreaContentRecord.find(params[:id])

    authorize @knowledge_area_content_record

    respond_with @knowledge_area_content_record
  end

  private

  def content_ids
    param_content_ids = params[:knowledge_area_content_record][:content_record_attributes][:content_ids] || []
    content_descriptions = params[:knowledge_area_content_record][:content_record_attributes][:content_descriptions] || []
    new_contents_ids = content_descriptions.map{|v| Content.find_or_create_by!(description: v).id }
    param_content_ids + new_contents_ids
  end

  def resource_params
    params.require(:knowledge_area_content_record).permit(
      :knowledge_area_ids,
      content_record_attributes: [
        :id,
        :unity_id,
        :classroom_id,
        :record_date,
        :content_ids
      ]
    )
  end

  def contents
    @contents = []
    teacher = current_teacher
    classroom = @knowledge_area_content_record.content_record.classroom
    knowledge_area = @knowledge_area_content_record.knowledge_area
    date = @knowledge_area_content_record.content_record.record_date
    if teacher && classroom && knowledge_area && date
      @contents = ContentsForKnowledgeAreaRecordFetcher.new(teacher, classroom, knowledge_area, date).fetch
    end
    if @knowledge_area_content_record.content_record.contents
      @contents << @knowledge_area_content_record.content_record.contents_ordered
    end
    @contents.flatten.uniq
  end
  helper_method :contents

  def all_contents
    Content.ordered
  end
  helper_method :all_contents

  def fetch_collections
    fetch_unities
    fetch_grades
    fetch_knowledge_areas
  end

  def unities
    @unities = [current_user_unity]
  end
  helper_method :unities

  def classrooms
    @classrooms = Classroom.by_unity_and_teacher(current_user_unity.id, current_teacher.id)
                           .ordered
  end
  helper_method :classrooms

  def knowledge_areas
    #@knowledge_areas = []

    #if @knowledge_area_content_record.content_record.classroom.present?
    #  @knowledge_areas = KnowledgeArea.by_teacher(current_teacher.id)
    #                              .by_grade(@knowledge_area_content_record.content_record.classroom.grade.id)
    #                              .ordered
    #end
    @knowledge_areas = KnowledgeArea.ordered
  end
  helper_method :knowledge_areas
end
