class BiometricTypes < EnumerateIt::Base
  associate_values :sagem => 1,
                   :inttelix => 2,
                   :suprema => 3

  sort_by :none
end
