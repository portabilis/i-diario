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
    @maintenance_adjustment = MaintenanceAdjustment.new(maintenance_adjustment_params.merge(workflow_attributes))
    authorize @maintenance_adjustment

    if @maintenance_adjustment.save
      start_maintenance_adjustment
      respond_with @maintenance_adjustment, location: maintenance_adjustments_path, notice: t('.notice')
    else
      render :new
    end
  end

  def update
    if @maintenance_adjustment.update(maintenance_adjustment_params.merge(workflow_attributes))
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
    _params = params.require(:maintenance_adjustment).permit(:year, :kind, :observations, :unity_ids)
    # O select2 customizado envia os ids como string separada por virgulas, mas
    # a associacao HABTM espera receber um array.
    _params[:unity_ids] = normalize_unity_ids(_params[:unity_ids])
    _params
  end

  def fetch_unities
    @unities = Unity.ordered
  end

  def start_maintenance_adjustment
    MaintenanceAdjustmentWorker.perform_async(current_entity.id, maintenance_adjustment_params[:unity_ids], current_user.id, @maintenance_adjustment.id)
  end

  def normalize_unity_ids(unity_ids)
    Array(unity_ids).flat_map { |value| value.to_s.split(',') }.reject(&:blank?)
  end

  def workflow_attributes
    {
      status: MaintenanceAdjustmentStatus::PENDING,
      error_message: nil
    }
  end
end
