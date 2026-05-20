module StudentStatusBadgeHelper
  def student_status_badge(status)
    render(partial: 'shared/student_status_badge', locals: { status: status })
  end
end
