class ContentRecordDecorator
  include Decore

  def author(current_teacher)
    PlanAuthorFetcher.new(component, current_teacher).author
  end
end
