class MenuDecorator
  include Decore
  include Decore::Proxy

  def self.data_for_select2
    ***REMOVED***s = Menu.includes(:***REMOVED***_type).ordered.group_by(&:***REMOVED***_type).map do |***REMOVED***_type, ***REMOVED***s|
      {
        name: ***REMOVED***_type.to_s,
        children: ***REMOVED***s.map { |s| { id: s.id, name: s.to_s, text: s.to_s } }
      }
    end
    insert_empty_element(***REMOVED***s) if ***REMOVED***s.any?
    ***REMOVED***s.to_json
  end

  private

  def self.insert_empty_element(elements)
    empty_element = { id: 'empty', name: '<option></option>', text: '' }
    elements.insert(0, empty_element)
  end
end
