class AfterSaleRelationshipOptions < EnumerateIt::Base
  associate_values :allows, :does_not_allow

  sort_by :none
end
