class SidekiqStatus < EnumerateIt::Base
  associate_values :ok, :not_ok

  sort_by :none
end
