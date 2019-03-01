class MaintenanceAdjustmentsController < ApplicationController
  before_action :set_maintenance_adjustment, only: [:edit, :update, :destroy, :history]
  before_action :fetch_unities, except: [:history]

  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @maintenance_adjustments = apply_scopes(MaintenanceAdjustment).ordered
    authorize @maintenance_adjustments
  end

  def new
    @maintenance_adjustment = MaintenanceAdjustment.new
    @maintenance_adjustment.status = MaintenanceAdjustmentStatus::PENDING
    authorize @maintenance_adjustment
  end

  def create
    @maintenance_adjustment = MaintenanceAdjustment.new(maintenance_adjustment_params)
    authorize @maintenance_adjustment

    if @maintenance_adjustment.save
      start_maintenance_adjustment
      respond_with @maintenance_adjustment, location: maintenance_adjustments_path, notice: t('.notice')
    else
      render :new
    end
  end

  def update
    if @maintenance_adjustment.update(maintenance_adjustment_params)
      start_maintenance_adjustment
      respond_with @maintenance_adjustment, location: maintenance_adjustments_path, notice: t('.notice')
    else
      render :new
    end
  end

  def destroy
    @maintenance_adjustment.destroy

    respond_with @maintenance_adjustment, location: maintenance_adjustments_path, alert: @maintenance_adjustment.errors.to_a
  end

  def history
    respond_with @maintenance_adjustment
  end

  def any_completed
    render json: { any_completed: MaintenanceAdjustment.where(id: params[:ids]).completed.exists? }
  end

  private

  def set_maintenance_adjustment
    @maintenance_adjustment = MaintenanceAdjustment.find(params[:id])
  end

  def maintenance_adjustment_params
    _params = params.require(:maintenance_adjustment).permit(:year, :kind, :observations, :status, :unity_ids)
    _params[:unity_ids] = _params[:unity_ids].split(",")
    _params
  end

  def fetch_unities
    @unities = Unity.ordered
  end

  def start_maintenance_adjustment
    MaintenanceAdjustmentWorker.perform_async(current_entity.id, maintenance_adjustment_params[:unity_ids], current_user.id, @maintenance_adjustment.id)
  end
end
