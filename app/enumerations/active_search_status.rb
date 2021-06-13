class ActiveSearchStatus < EnumerateIt::Base
  associate_values abandonment: 1,
                   in_progress: 2,
                   return: 3

  sort_by :none
end
