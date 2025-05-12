class TestSettingsController < ApplicationController
  respond_to :json, only: [:show]

  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @test_settings = apply_scopes(TestSetting.ordered)

    authorize @test_settings
  end

  def show
   @test_setting = resource

    render json: @test_setting
  end

  def new
    @test_setting = resource
    authorize resource

    unities

    @school_terms
  end

  def create
    resource.assign_attributes(resource_params.to_h)

    authorize resource

    if resource.save
      respond_with resource, location: test_settings_path
    else
      unities

      render :new
    end
  end

  def edit
    @test_setting = resource

    unities

    authorize resource
  end

  def update
    resource.assign_attributes(resource_params.to_h)

    authorize resource

    if resource.save
      respond_with resource, location: test_settings_path
    else
      unities

      render :edit
    end
  end

  def destroy
    authorize resource

    resource.destroy

    respond_with resource, location: test_settings_path
  end

  def history
    @test_setting = TestSetting.find(params[:id])

    authorize @test_setting

    respond_with @test_setting
  end

  def grades_by_unities
    return if params[:unities].blank?

    unities = params[:unities].split(',')

    render json: grades_by_unity_to_select2(unities)
  end

  private

  def resource
    @test_setting ||= case params[:action]
    when 'new', 'create'
      TestSetting.new
    when 'show', 'edit', 'update', 'destroy'
      TestSetting.find(params[:id])
    end.localized
  end

  def resource_params
    parameters = params.require(:test_setting)
                       .permit(:exam_setting_type,
                               :year,
                               :school_term_type_step_id,
                               :maximum_score,
                               :minimum_score,
                               :number_of_decimal_places,
                               :average_calculation_type,
                               :unities,
                               :grades,
                               :default_division_weight,
                               tests_attributes: [:id,
                                                  :description,
                                                  :weight,
                                                  :test_type,
                                                  :allow_break_up,
                                                  :_destroy])

    parameters[:unities] = parameters[:unities].split(',')
    parameters[:grades] = parameters[:grades].split(',')

    parameters
  end

  def unities
    @unities ||= begin
      @unities = []
      Unity.with_api_code.uniq.each do |unity|
        @unities << OpenStruct.new(id: unity.id, text: unity.name, name: unity.name)
      end
    end
  end

  def grades
    return [] if action_name == 'new'

    unities = action_name == 'edit' ? resource.unities : resource_params[:unities]

    grades_by_unity_to_select2(unities)
  end
  helper_method :grades

  def grades_by_unity_to_select2(unities)
    grades_to_select2 = []

    Grade.includes(:course).by_unity(unities).each do |grade|
      grades_to_select2 << OpenStruct.new(
        id: grade.id,
        name: "#{grade.description} - #{grade.course.description}",
        text: "#{grade.description} - #{grade.course.description}"
      )
    end

    grades_to_select2
  end
end
