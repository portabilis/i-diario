class RecoveryTypes < EnumerateIt::Base
  associate_values :dont_use => 0,
                   :parallel => 1,
                   :specific => 2

  sort_by :none
end
