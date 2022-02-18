class ComplementaryExamSettingsController < ApplicationController
  has_scope :page, default: 1, only: [:index]
  has_scope :per, default: 10, only: [:index]

  respond_to :html, :js, :json

  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]

  def index
    @complementary_exam_settings = apply_scopes(ComplementaryExamSetting).includes(:grades).ordered
    authorize @complementary_exam_settings

    respond_with @complementary_exam_settings
  end

  def show
    render json: resource
  end

  def new
    resource
    authorize resource
  end

  def create
    assign_attributes(resource)

    authorize resource

    if resource.save
      respond_with resource, location: complementary_exam_settings_path
    else
      render :new
    end
  end

  def edit
    @complementary_exam_setting = resource

    authorize @complementary_exam_setting
  end

  def update
    @complementary_exam_setting = resource

    assign_attributes(@complementary_exam_setting.localized)

    authorize @complementary_exam_setting

    if resource.save
      respond_with resource, location: complementary_exam_settings_path
    else
      render :edit
    end
  end

  def destroy
    authorize resource

    resource_destroyer = ResourceDestroyer.new.destroy(resource)
    if resource_destroyer.has_error?
      flash[:error] = resource_destroyer.error_message
      flash[:notice] = ""
    end
    respond_with resource, location: complementary_exam_settings_path
  end

  def history
    @complementary_exam_setting = ComplementaryExamSetting.find(params[:id])

    authorize @complementary_exam_setting

    respond_with @complementary_exam_setting
  end

  private

  def grades
    @grades ||= Grade.includes(:course)
                     .joins(classrooms_grades: :exam_rule)
                     .merge(ExamRule.where(score_type: ScoreTypes::NUMERIC))
                     .ordered
                     .uniq
  end
  helper_method :grades

  def assign_attributes(model)
    model.assign_attributes(resource_params)
    model.grade_ids = (params[:complementary_exam_setting][:grade_ids]||'').split(',')
  end

  def resource
    @complementary_exam_setting ||= case params[:action]
    when 'new', 'create'
      ComplementaryExamSetting.new
    when 'edit', 'update', 'destroy', 'show'
      ComplementaryExamSetting.find(params[:id])
    end
  end

  def resource_params
    params.require(:complementary_exam_setting)
          .permit(:description,
                  :initials,
                  :affected_score,
                  :calculation_type,
                  :maximum_score,
                  :number_of_decimal_places,
                  :year)
  end
end
