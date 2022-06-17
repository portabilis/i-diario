module SchoolCalendarEventBatchHelper
  def formatted_date(object, date)
    object.new_record? ? nil : l(date)
  end
end
