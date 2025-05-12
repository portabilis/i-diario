class KnowledgeAreaContentRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_classroom, only: [:index, :new, :edit, :create, :update]
  before_action :require_current_teacher
  before_action :require_current_classroom, only: [:index, :new, :create, :edit, :update, :show]
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy, :clone]

  def index
    params[:filter] ||= {}
    author_type = PlansAuthors::MY_PLANS if params[:filter].empty?
    author_type ||= (params[:filter] || []).delete(:by_author)

    set_options_by_user
    set_knowledge_area_by_classroom(@classrooms.map(&:id))

    @knowledge_area_content_records = fetch_knowledge_area_content_records_by_user

    if author_type.present?
      @knowledge_area_content_records = @knowledge_area_content_records.by_author(author_type, current_teacher)
      params[:filter][:by_author] = author_type
    end

    authorize @knowledge_area_content_records
  end

  def show
    @knowledge_area_content_record = KnowledgeAreaContentRecord.find(params[:id]).localized

    set_options_by_user
    set_knowledge_area_by_classroom(@knowledge_area_content_record.classroom_id)

    authorize @knowledge_area_content_record
  end

  def new
    @knowledge_area_content_record = KnowledgeAreaContentRecord.new.localized
    @knowledge_area_content_record.build_content_record(
      record_date: Time.zone.now,
      unity_id: current_unity.id,
      classroom_id: current_user_classroom.id
    )

    set_options_by_user
    set_knowledge_area_by_classroom(current_user_classroom.id)
    authorize @knowledge_area_content_record
  end

  def create
    @knowledge_area_content_record = KnowledgeAreaContentRecord.new(resource_params)
    @knowledge_area_content_record.knowledge_area_ids = resource_params[:knowledge_area_ids].split(',')
    @knowledge_area_content_record.content_record.teacher = current_teacher
    @knowledge_area_content_record.content_record.content_ids = content_ids
    @knowledge_area_content_record.content_record.origin = OriginTypes::WEB
    @knowledge_area_content_record.content_record.creator_type = 'knowledge_area_content_record'
    @knowledge_area_content_record.content_record.teacher = current_teacher
    @knowledge_area_content_record.teacher_id = current_teacher_id

    authorize @knowledge_area_content_record

    if @knowledge_area_content_record.save
      respond_with @knowledge_area_content_record, location: knowledge_area_content_records_path
    else
      set_options_by_user
      set_knowledge_area_by_classroom(@knowledge_area_content_record.classroom_id)
      render :new
    end
  end

  def edit
    @knowledge_area_content_record = KnowledgeAreaContentRecord.find(params[:id]).localized

    set_options_by_user
    set_knowledge_area_by_classroom(@knowledge_area_content_record.classroom_id)

    authorize @knowledge_area_content_record
  end

  def update
    @knowledge_area_content_record = KnowledgeAreaContentRecord.find(params[:id])
    @knowledge_area_content_record.assign_attributes(resource_params)
    @knowledge_area_content_record.knowledge_area_ids = resource_params[:knowledge_area_ids].split(',')
    @knowledge_area_content_record.content_record.content_ids = content_ids
    @knowledge_area_content_record.teacher_id = current_teacher_id
    @knowledge_area_content_record.content_record.current_user = current_user

    authorize @knowledge_area_content_record

    if @knowledge_area_content_record.save
      respond_with @knowledge_area_content_record, location: knowledge_area_content_records_path
    else
      set_options_by_user
      set_knowledge_area_by_classroom(@knowledge_area_content_record.classroom_id)

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

  def clone
    @form = KnowledgeAreaContentRecordClonerForm.new(clone_params.merge(teacher: current_teacher))

    flash[:success] = t('messages.copy_succeed') if @form.clone!
  end

  private

  def fetch_knowledge_area_content_records_by_user
    apply_scopes(KnowledgeAreaContentRecord
      .includes(:knowledge_areas, content_record: [:classroom])
      .by_classroom_id(@classrooms.map(&:id))
      .order_by_classroom
      .ordered)
  end

  def content_ids
    param_content_ids = params[:knowledge_area_content_record][:content_record_attributes][:content_ids] || []
    content_descriptions = params[:knowledge_area_content_record][:content_record_attributes][:content_descriptions] || []
    new_contents_ids = content_descriptions.map { |content_description|
      Content.find_or_create_by!(description: content_description).id
    }
    param_content_ids + new_contents_ids
  end

  def resource_params
    params.require(:knowledge_area_content_record).permit(
      :knowledge_area_ids,
      :experience_fields,
      content_record_attributes: [
        :id,
        :unity_id,
        :classroom_id,
        :record_date,
        :daily_activities_record,
        :content_ids
      ]
    )
  end

  def clone_params
    params.require(:knowledge_area_content_record_cloner_form).permit(
      :knowledge_area_content_record_id,
      knowledge_area_content_record_item_cloner_form_attributes: [
        :uuid,
        :classroom_id,
        :record_date
      ]
    )
  end

  def contents
    @contents = []
    teacher = current_teacher
    classroom = @knowledge_area_content_record.content_record.classroom
    knowledge_areas = @knowledge_area_content_record.knowledge_areas
    date = @knowledge_area_content_record.content_record.record_date

    if teacher && classroom && knowledge_areas && date
      @contents = ContentsForKnowledgeAreaRecordFetcher.new(teacher, classroom, knowledge_areas, date).fetch
      @contents.each { |content| content.is_editable = false }
    end

    if @knowledge_area_content_record.content_record.contents
      contents = @knowledge_area_content_record.content_record.contents_ordered
      contents.each { |content| content.is_editable = true }
      @contents << contents
    end

    @contents.flatten.uniq
  end
  helper_method :contents

  def all_contents
    Content.ordered
  end
  helper_method :all_contents

  def unities
    @unities = [current_unity]
  end
  helper_method :unities

  def set_options_by_user
    return fetch_linked_by_teacher unless current_user.current_role_is_admin_or_employee?

    @classrooms = [current_user_classroom]
  end

  def set_knowledge_area_by_classroom(classroom_id)
    @knowledge_areas = KnowledgeArea.by_teacher(current_teacher)
                                    .by_classroom_id(classroom_id)
                                    .ordered
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms ||=  @fetch_linked_by_teacher[:classrooms]
    @disciplines ||= @fetch_linked_by_teacher[:disciplines]
  end
end
