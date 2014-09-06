module Helpers
  def click_***REMOVED***(***REMOVED***)
    ***REMOVED*** = ***REMOVED***.split(" > ")

    within "#left-panel" do
      click_on ***REMOVED***[0]

      within "li.open" do
        click_link ***REMOVED***[1]
      end
    end
  end

  def fill_mask(locator, options = {})
    msg = "cannot fill in, no text field with id, name, or label '#{locator}' found"
    raise "Must pass a hash containing 'with'" if not options.is_a?(Hash) or not options.has_key?(:with)

    field = page.find_field(locator)
    page.execute_script %{document.getElementById('#{field[:id]}').value = '#{options[:with]}'}
    field.trigger('blur')
  end
end

RSpec.configure do |config|
  config.include Helpers, type: :feature
end

