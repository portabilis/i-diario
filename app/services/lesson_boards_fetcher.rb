class LessonBoardsFetcher
  def initialize(user)
    @user = user
  end

  def lesson_boards
    @lesson_boards = LessonsBoard.by_unity(unities)
    @lesson_boards.ordered
  end

  def unities
    if @user.current_user_role.try(:role_administrator?)
      @unities ||= Unity.joins(:school_calendars)
                        .where(school_calendars: { year: @user.current_school_year })
                        .ordered
    else
      [current_user_unity]
    end
  end
end
