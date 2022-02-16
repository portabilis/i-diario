class LessonBoardsFetcher
  def initialize(user)
    @user = user
  end

  def lesson_boards
    @lesson_boards = LessonsBoard.by_unity(unities)
    @lesson_boards.joins(classrooms_grade: :classroom).order('classrooms.description')
  end

  def unities
    if @user.current_user_role.try(:role_administrator?)
      Unity.joins(:school_calendars)
           .where(school_calendars: { year: @user.current_school_year })
           .ordered
    else
      lessons_unities = []
      roles_ids = Role.where(access_level: AccessLevel::EMPLOYEE).pluck(:id)
      unities_user = UserRole.where(user_id: @user.id, role_id: roles_ids).pluck(:unity_id)
      LessonsBoard.by_unity(unities_user).each { |lesson_board| lessons_unities << lesson_board.classroom.unity.id }
      Unity.where(id: lessons_unities).ordered
    end
  end
end
