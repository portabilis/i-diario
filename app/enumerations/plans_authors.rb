class PlansAuthors < EnumerateIt::Base
  associate_values :my_plans, :others

  sort_by :none
end
