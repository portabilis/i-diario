class DisciplineContentRecordsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_classroom, only: [:index, :new, :edit, :create, :update]
  before_action :require_current_teacher
  before_action :require_current_classroom, only: [:index, :new, :create, :edit, :update]
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy, :clone]
  before_action :set_number_of_classes, only: [:new, :create, :edit, :show]
  before_action :allow_class_number, only: [:index, :new, :edit, :show]

  def index
    params[:filter] ||= {}
    author_type = PlansAuthors::MY_PLANS if params[:filter].empty?
    author_type ||= (params[:filter] || []).delete(:by_author)

    set_options_by_user

    fetch_discipline_content_records_by_user

    if author_type.present?
      @discipline_content_records = @discipline_content_records.by_author(author_type, current_teacher)
      params[:filter][:by_author] = author_type
    end

    authorize @discipline_content_records
  end

  def show
    @discipline_content_record = DisciplineContentRecord.find(params[:id]).localized

    authorize @discipline_content_record
  end

  def new
    set_options_by_user

    @discipline_content_record = DisciplineContentRecord.new.localized
    @discipline_content_record.discipline_id = current_user_discipline.id
    @discipline_content_record.build_content_record(
      record_date: Time.zone.now,
      unity_id: current_unity.id,
      classroom_id: current_user_classroom.id
    )
    @class_numbers = []

    unless current_user.current_role_is_admin_or_employee?
      classroom_id = @discipline_content_record.content_record.classroom_id
      @disciplines = @disciplines.by_classroom_id(classroom_id).not_descriptor
    end

    authorize @discipline_content_record
  end

  def create
    @discipline_content_record = DisciplineContentRecord.new(resource_params)
    @discipline_content_record.content_record.teacher = current_teacher
    @discipline_content_record.content_record.content_ids = content_ids
    @discipline_content_record.content_record.origin = OriginTypes::WEB
    @discipline_content_record.content_record.creator_type = 'discipline_content_record'
    @discipline_content_record.content_record.teacher = current_teacher
    @discipline_content_record.teacher_id = current_teacher_id

    authorize @discipline_content_record

    return render_content_with_multiple_class_numbers if allow_class_number

    if @discipline_content_record.save && validate_class_numbers
      respond_with @discipline_content_record, location: discipline_content_records_path
    else
      set_options_by_user

      render :new
    end
  end

  def edit
    set_options_by_user

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
      set_options_by_user

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

  def render_content_with_multiple_class_numbers
    @class_numbers = resource_params[:class_number].split(',').sort
    @discipline_content_record.class_number = @class_numbers.first

    @class_numbers.each do |class_number|
      @discipline_content_record.class_number = class_number

      return render :new if @discipline_content_record.invalid?
    end

    multiple_content_creator = CreateMultipleContents.new(@class_numbers, @discipline_content_record)

    if multiple_content_creator.call
      respond_with @discipline_content_record, location: discipline_content_records_path
    else
      set_options_by_user

      render :new
    end
  end

  def fetch_discipline_content_records_by_user
    @discipline_content_records =
      apply_scopes(DisciplineContentRecord
        .includes(:discipline, content_record: [:classroom])
        .by_unity_id(current_unity.id)
        .by_classroom_id(@classrooms.map(&:id))
        .by_discipline_id(@disciplines.map(&:id))
        .order_by_classroom
        .ordered)
  end

  def allow_class_number
    @allow_class_number ||= GeneralConfiguration.first.allow_class_number_on_content_records
  end

  def set_number_of_classes
    @number_of_classes = current_school_calendar.number_of_classes
  end

  def validate_class_numbers
    return true unless allow_class_number
    return true if @class_numbers.present?

    @error_on_class_numbers = true
    flash.now[:alert] = t('errors.daily_frequencies.class_numbers_required_when_not_global_absence')

    false
  end

  def content_ids
    param_content_ids = params[:discipline_content_record][:content_record_attributes][:content_ids] || []
    content_descriptions = params[:discipline_content_record][:content_record_attributes][:content_descriptions] || []
    new_contents_ids = content_descriptions.map{|v| Content.find_or_create_by!(description: v).id }
    param_content_ids + new_contents_ids
  end

  def resource_params
    params.require(:discipline_content_record).permit(
      :class_number,
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
      ).ordered
    end

    @disciplines
  end
  helper_method :disciplines

  def set_options_by_user
    return fetch_linked_by_teacher unless current_user.current_role_is_admin_or_employee?

    @classrooms ||= [current_user_classroom]
    @disciplines ||= [current_user_discipline]
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms ||=  @fetch_linked_by_teacher[:classrooms]
    @disciplines ||= @fetch_linked_by_teacher[:disciplines]
  end
end
