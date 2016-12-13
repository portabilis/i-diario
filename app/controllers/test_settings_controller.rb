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
    @school_terms
  end

  def create
    resource.assign_attributes resource_params

    authorize resource

    if resource.save
      respond_with resource, location: test_settings_path
    else
      render :new
    end
  end

  def edit
    @test_setting = resource

    authorize resource
  end

  def update
    resource.assign_attributes resource_params

    authorize resource

    if resource.save
      respond_with resource, location: test_settings_path
    else
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
    params.require(:test_setting).permit(:exam_setting_type,
                                         :year,
                                         :school_term,
                                         :maximum_score,
                                         :number_of_decimal_places,
                                         :fix_tests,
                                         tests_attributes: [:id,
                                                            :description,
                                                            :weight,
                                                            :test_type,
                                                            :allow_break_up,
                                                            :_destroy])
  end
end
