class AvaliationExemptionsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher

  def index
    @avaliation_exemptions = apply_scopes(AvaliationExemption)
    authorize @avaliation_exemptions
  end

  def new
    @avaliation_exemption = AvaliationExemption.new
    @unities = fetch_unities
    authorize @avaliation_exemption
  end

  def create
    @avaliation_exemption = AvaliationExemption.new.localized
    @avaliation_exemption.assign_attributes(avaliation_exemption_params)

    authorize @avaliation_exemption

    if @avaliation_exemption.save
      respond_with @avaliation_exemption, location: avaliation_exemption_path
    else
      render :new
    end
  end

  def edit
    @avaliation_exemption = AvaliationExemption.find(params[:id]).localized
    authorize @avaliation_exemption
  end

  def update
    @avaliation_exemption = AvaliationExemption.find(params[:id]).localized

    authorize @avaliation_exemption

    if @avaliation_exemption.update_attributes(avaliation_exemption_params)
      respond_with @avaliation_exemption, location: avaliation_exemption_path
    else
      render :edit
    end
  end

  def destroy
    @avaliation_exemption = AvaliationExemption.find(params[:id])

    authorize @avaliation_exemption

    @avaliation_exemption.destroy

    respond_with @avaliation_exemption, location: avaliation_exemption_path, alert: @avaliation_exemption.errors.to_a
  end

  def history
    @avaliation_exemption = AvaliationExemption.find(params[:id]).localized

    authorize @avaliation_exemption

    respond_with @avaliation_exemption
  end

  def avaliation_exemption_params
    params.require(:avaliation_exemption).permit(:student_id,
                                                 :avaliation_id,
                                                 :reason)
  end

  def fetch_unities
    Unity.by_teacher(current_teacher)
  end

end
