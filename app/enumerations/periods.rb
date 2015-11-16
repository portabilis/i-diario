class Periods < EnumerateIt::Base
  associate_values matutinal: '1',
                   vespertine: '2',
                   nightly: '3',
                   full: '4',
                   intermediate: '5'

  sort_by :none
end
