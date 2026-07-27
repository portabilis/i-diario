# Restringe o acesso aos PEIs às turmas do usuário (admin: turma do perfil; professor: as que
# leciona). Compartilhado entre os controllers de PEI e de versões para fechar o IDOR das telas de
# leitura: plano de turma sem vínculo → RecordNotFound.
module IndividualizedEducationalPlanScoping
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :individualized_educational_plan_not_found
  end

  private

  def individualized_educational_plan_not_found
    redirect_to individualized_educational_plans_path,
                alert: I18n.t('individualized_educational_plans.flash.not_found')
  end

  def accessible_classrooms
    @accessible_classrooms ||=
      if current_user.current_role_is_admin_or_employee?
        [current_user_classroom].compact
      else
        fetched = TeacherClassroomAndDisciplineFetcher.fetch!(
          current_teacher.id, current_unity, current_school_year
        )
        fetched ? fetched[:classrooms] : []
      end
  end

  def accessible_plans
    IndividualizedEducationalPlan.by_classroom_id(accessible_classrooms.map(&:id))
  end
end
