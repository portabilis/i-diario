module Capybara
  module RSpecMatchers
    def have_select2(*args)
      HaveSelect2.new(*args)
    end

    def have_select2_disabled(*args)
      HaveSelect2Disabled.new(*args)
    end

    def have_select2_filled(*args)
      HaveSelect2Filled.new(*args)
    end
  end
end
