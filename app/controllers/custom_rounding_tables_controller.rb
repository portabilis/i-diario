class CustomRoundingTablesController < ApplicationController
  before_action :set_custom_rounding_table, only: [:edit, :update, :destroy, :history]
  before_action :fetch_unities, :fetch_grades, except: [:history]

  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @custom_rounding_tables = apply_scopes(CustomRoundingTable).ordered
    authorize @custom_rounding_tables
  end

  def new
    @custom_rounding_table = CustomRoundingTable.new

    (0..9).each do |item|
      value = @custom_rounding_table.custom_rounding_table_values.new
      value.label = item.to_s
      value.action = RoundingTableAction::NONE
    end

    authorize @custom_rounding_table
  end

  def edit
  end

  def create
    @custom_rounding_table = CustomRoundingTable.new(custom_rounding_table_params)

    authorize @custom_rounding_table

    if @custom_rounding_table.save
      respond_with @custom_rounding_table, location: custom_rounding_tables_path
    else
      render :new
    end
  end

  def update
    if @custom_rounding_table.update(custom_rounding_table_params)
      respond_with @custom_rounding_table, location: custom_rounding_tables_path
    else
      render :new
    end
  end

  def destroy
    @custom_rounding_table.destroy

    respond_with @custom_rounding_table, location: custom_rounding_tables_path, alert: @custom_rounding_table.errors.to_a
  end

  def history
    respond_with @custom_rounding_table
  end

  private
    def set_custom_rounding_table
      @custom_rounding_table = CustomRoundingTable.find(params[:id])

      authorize @custom_rounding_table
    end

    def custom_rounding_table_params
      _params = params.require(:custom_rounding_table).permit(:name, :year, :unity_ids, :grade_ids,
        custom_rounding_table_values_attributes: [:id, :custom_rounding_table_id, :label, :action, :exact_decimal_place])

      _params[:unity_ids] = _params[:unity_ids].split(",")
      _params[:grade_ids] = _params[:grade_ids].split(",")

      _params
    end

    def fetch_unities
      @unities = Unity.ordered
    end

    def fetch_grades
      @grades = Grade.ordered
    end
end
