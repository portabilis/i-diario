class DisciplineContentRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy, :clone]

  def index
    params[:filter] ||= {}
    author_type = PlansAuthors::MY_PLANS if params[:filter].empty?
    author_type ||= (params[:filter] || []).delete(:by_author)

    @discipline_content_records = apply_scopes(
      DisciplineContentRecord.includes(:discipline, content_record: [:classroom])
                             .by_unity_id(current_unity.id)
                             .by_classroom_id(current_user_classroom)
                             .by_discipline_id(current_user_discipline)
                             .ordered
    )

    if author_type.present?
      @discipline_content_records = @discipline_content_records.by_author(author_type, current_teacher)
      params[:filter][:by_author] = author_type
    end

    authorize @discipline_content_records
  end

  def new
    @discipline_content_record = DisciplineContentRecord.new.localized
    @discipline_content_record.build_content_record(
      record_date: Time.zone.now,
      unity_id: current_unity.id
    )

    authorize @discipline_content_record
  end

  def create
    @discipline_content_record = DisciplineContentRecord.new(resource_params)
    @discipline_content_record.content_record.teacher = current_teacher
    @discipline_content_record.content_record.content_ids = content_ids
    @discipline_content_record.content_record.origin = OriginTypes::WEB
    @discipline_content_record.content_record.teacher = current_teacher
    @discipline_content_record.teacher_id = current_teacher_id

    authorize @discipline_content_record

    if @discipline_content_record.save
      respond_with @discipline_content_record, location: discipline_content_records_path
    else
      render :new
    end
  end

  def edit
    @discipline_content_record = DisciplineContentRecord.find(params[:id]).localized

    authorize @discipline_content_record
  end

  def update
    @discipline_content_record = DisciplineContentRecord.find(params[:id])
    @discipline_content_record.assign_attributes(resource_params)
    @discipline_content_record.content_record.content_ids = content_ids
    @discipline_content_record.teacher_id = current_teacher_id
    @discipline_content_record.content_record.current_user = current_user
    @discipline_content_record.current_user = current_user

    authorize @discipline_content_record

    if @discipline_content_record.save
      respond_with @discipline_content_record, location: discipline_content_records_path
    else
      render :edit
    end
  end

  def destroy
    @discipline_content_record = DisciplineContentRecord.find(params[:id]).localized

    authorize @discipline_content_record

    @discipline_content_record.destroy

    respond_with @discipline_content_record, location: discipline_content_records_path
  end

  def history
    @discipline_content_record = DisciplineContentRecord.find(params[:id])

    authorize @discipline_content_record

    respond_with @discipline_content_record
  end

  def clone
    @form = DisciplineContentRecordClonerForm.new(clone_params.merge(teacher: current_teacher))

    if @form.clone!
      flash[:success] = "Registro de conteúdo por disciplina copiado com sucesso!"
    end
  end

  private

  def content_ids
    param_content_ids = params[:discipline_content_record][:content_record_attributes][:content_ids] || []
    content_descriptions = params[:discipline_content_record][:content_record_attributes][:content_descriptions] || []
    new_contents_ids = content_descriptions.map{|v| Content.find_or_create_by!(description: v).id }
    param_content_ids + new_contents_ids
  end

  def resource_params
    params.require(:discipline_content_record).permit(
      :discipline_id,
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
    params.require(:discipline_content_record_cloner_form).permit(
      :discipline_content_record_id,
      discipline_content_record_item_cloner_form_attributes: [
        :uuid,
        :classroom_id,
        :record_date
      ]
    )
  end

  def contents
    @contents = []
    teacher = current_teacher
    classroom = @discipline_content_record.content_record.classroom
    discipline = @discipline_content_record.discipline
    date = @discipline_content_record.content_record.record_date

    if teacher && classroom && discipline && date
      @contents = ContentsForDisciplineRecordFetcher.new(teacher, classroom, discipline, date).fetch
      @contents.each { |content| content.is_editable = false }
    end

    if @discipline_content_record.content_record.contents
      contents = @discipline_content_record.content_record.contents_ordered
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

  def fetch_collections
    fetch_unities
    fetch_grades
    fetch_disciplines
  end

  def unities
    @unities = [current_unity]
  end
  helper_method :unities

  def classrooms
    @classrooms = Classroom.by_unity_and_teacher(current_unity.id, current_teacher.id).ordered
  end
  helper_method :classrooms

  def disciplines
    @disciplines = []

    if @discipline_content_record.content_record.classroom.present?
      @disciplines = Discipline.by_teacher_and_classroom(
          current_teacher.id, @discipline_content_record.content_record.classroom.id
        )
        .ordered
    end

    @disciplines
  end
  helper_method :disciplines
end
