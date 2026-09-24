class DailyNoteStudentPresenter < BasePresenter
  def number_of_decimal_places
    daily_note.avaliation
              .test_setting
              .number_of_decimal_places
  end

  def status_badge
    return :active_search            if in_active_search
    return :inactive                 unless active
    return :exempted                 if exempted
    return :dependence               if dependence
    return :exempted_from_discipline if exempted_from_discipline
  end
end
