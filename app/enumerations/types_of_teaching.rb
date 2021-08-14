class TypesOfTeaching < EnumerateIt::Base
  associate_values presential: 1,
                   hybrid: 2,
                   remote: 3
  sort_by :none
end
