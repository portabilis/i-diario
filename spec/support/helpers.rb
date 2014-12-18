module Helpers
  def click_***REMOVED***(***REMOVED***)
    ***REMOVED*** = ***REMOVED***.split(" > ")

    within "#left-panel" do
      click_on ***REMOVED***[0]

      if ***REMOVED***[1]
        within "li.open" do
          click_link ***REMOVED***[1]
        end
      end
    end
  end

  def close_modal
    page.execute_script %{
      $('.modal').modal('hide')
    }
  end

  def fill_autocomplete(field, options)
    fill_in field, with: options[:with]

    field_id = page.find_field(field)[:id]

    page.execute_script %Q{ $('##{field_id}').trigger('keyup'); }

    sleep 1
    page.execute_script %Q{ $("ul.typeahead a:contains(#{options.fetch(:with)})").trigger('mouseenter').click(); }
  end

  def fill_mask(locator, options = {})
    msg = "cannot fill in, no text field with id, name, or label '#{locator}' found"
    raise "Must pass a hash containing 'with'" if not options.is_a?(Hash) or not options.has_key?(:with)

    field = page.find_field(locator)
    page.execute_script %{document.getElementById('#{field[:id]}').value = '#{options[:with]}'}
    field.trigger('blur')
  end

  def fill_in_select2(selector, options={})
    if options[:new]
      page.execute_script %{
        $('##{selector}').select2('val', '#{options[:with]}', true);
      }
    else
      expect(page).to have_field selector

      field = page.find_field selector

      page.execute_script %{
        $('##{field[:id]}').parent().next().select2('val', '#{options[:with]}', true);
      }
    end
  end
end

RSpec.configure do |config|
  config.include Helpers, type: :feature
end
