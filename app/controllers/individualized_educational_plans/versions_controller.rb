module IndividualizedEducationalPlans
  class VersionsController < ApplicationController
    include RendersIepPdf

    before_action :require_current_teacher
    before_action :require_current_classroom
    # Controller aninhado: título/breadcrumb/menu usam o item do PEI no navigation.yml.
    before_action { @navigation_item = 'individualized_educational_plans' }

    def self._prefixes
      super + ['individualized_educational_plans']
    end

    def index
      @individualized_educational_plan = IndividualizedEducationalPlan.find(
        params[:individualized_educational_plan_id]
      )
      authorize @individualized_educational_plan, :show?

      @versions = @individualized_educational_plan.iep_versions.includes(:published_by).recent_first
    end

    # Visualização de uma versão publicada: reconstrói o PEI congelado a partir do
    # snapshot (imutável) e renderiza a MESMA tela de formulário em modo leitura.
    def show
      iep = IndividualizedEducationalPlan.find(params[:individualized_educational_plan_id])
      @version = iep.iep_versions.find(params[:id])

      authorize iep, :show?

      respond_to do |format|
        # HTML: reconstrói a versão congelada e renderiza o mesmo formulário em modo leitura.
        format.html do
          restored = IndividualizedEducationalPlanSnapshotRestorer.restore(@version.content)
          @individualized_educational_plan = restored.plan
          @students = restored.students
          @aee_teachers = restored.aee_teachers
          @iep_options_by_kind = restored.iep_options_by_kind
          @frozen_attachments = restored.attachments
          # Modal de adicionar componente não é renderizado no modo leitura (não precisa das listas).
          @disciplines = []
          @knowledge_areas = []
        end
        # PDF: documento de impressão (flat) a partir do snapshot imutável da versão.
        format.pdf do
          @presenter = IndividualizedEducationalPlanReportPresenter.from_snapshot(@version.content)
          send_iep_pdf(
            filename: "plano_educacional_individualizado_#{iep.id}_versao_#{@version.id}.pdf",
            log_context: "plan #{iep.id} version #{@version.id}"
          )
        end
      end
    end
  end
end
