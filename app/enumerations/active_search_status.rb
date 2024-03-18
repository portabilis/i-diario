class ActiveSearchStatus < EnumerateIt::Base
  associate_values abandonment: 1,
                   in_progress: 2,
                   return_with_justification: 3,
                   return: 4,
                   transfer: 5

  sort_by :none
end
