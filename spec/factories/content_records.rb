FactoryGirl.define do
  factory :content_record do
    teacher
    classroom

    transient do
      contents_count 1
    end

    before(:create) do |content_record, evaluator|
      content_record.contents = create_list(:content, evaluator.contents_count)
    end

    before(:create) do |content_record, evaluator|
      content_record.contents = create_list(:content, evaluator.contents_count)
      school_calendar = create(:school_calendar_with_one_step, unity: content_record.unity, year: Date.current.year)
      content_record.record_date = 1.business_days.after(Date.parse("#{school_calendar.year}-01-01"))
    end
  end
end
