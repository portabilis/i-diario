class LessonBoardsFetcher
  def initialize(user)
    @user = user
  end

  def lesson_boards
    LessonsBoard.by_unity(unity_ids)
  end

  def unities
    @unities ||= administrator? ? unities_with_school_calendar : employee_unities
  end

  def unity_ids
    @unity_ids ||= unities.map(&:id)
  end

  def administrator?
    @user.current_user_role.try(:role_administrator?)
  end

  private

  def unities_with_school_calendar
    Unity.joins(:school_calendars)
         .where(school_calendars: { year: @user.current_school_year })
         .distinct
         .ordered
  end

  # As unidades saem direto dos vínculos do usuário: a restrição "somente unidades com quadro de
  # aula" é aplicada nas opções do filtro (LessonsBoardsFilterOptionsQuery), sem precisar carregar
  # todos os quadros para descobrir as unidades.
  def employee_unities
    roles_ids = Role.where(access_level: AccessLevel::EMPLOYEE).pluck(:id)
    unities_user = UserRole.where(user_id: @user.id, role_id: roles_ids).pluck(:unity_id).compact

    Unity.where(id: unities_user).ordered
  end
end
