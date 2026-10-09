class RecoveryDiaryRecordStudentPresenter < BasePresenter
  def status_badge
    return :active_search            if in_active_search
    return :inactive                 unless active
    return :dependence               if dependence
    return :exempted_from_discipline if exempted_from_discipline
  end
end
