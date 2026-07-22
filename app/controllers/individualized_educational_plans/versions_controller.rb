module IndividualizedEducationalPlans
  class VersionsController < ApplicationController
    include RendersIepPdf

    before_action :require_current_teacher
    before_action :require_current_classroom
    # Controller aninhado: título/breadcrumb/menu usam o item do PEI no navigation.yml.
    before_action { @navigation_item = 'individualized_educational_plans' }

    def index
      @individualized_educational_plan = IndividualizedEducationalPlan.find(
        params[:individualized_educational_plan_id]
      )
      @versions = @individualized_educational_plan.iep_versions.includes(:published_by).recent_first

      authorize @individualized_educational_plan, :show?
    end

    # Visualização de uma versão publicada: renderiza a partir do snapshot (imutável).
    def show
      @individualized_educational_plan = IndividualizedEducationalPlan.find(
        params[:individualized_educational_plan_id]
      )
      @version = @individualized_educational_plan.iep_versions.find(params[:id])
      @presenter = IndividualizedEducationalPlanReportPresenter.from_snapshot(@version.content)

      authorize @individualized_educational_plan, :show?

      respond_to do |format|
        format.html
        format.pdf do
          send_iep_pdf(
            filename: "plano_educacional_individualizado_#{@individualized_educational_plan.id}_versao_#{@version.id}.pdf",
            log_context: "plan #{@individualized_educational_plan.id} version #{@version.id}"
          )
        end
      end
    end
  end
end
