class ContentRecordReportTypes < EnumerateIt::Base
  associate_values :lesson_plan => "1",
                   :content_record => "2"

  sort_by :none
end
