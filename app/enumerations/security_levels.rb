class SecurityLevels < EnumerateIt::Base
  associate_values :basic, :advanced

  sort_by :none
end
