class MenuDecorator
  include Decore
  include Decore::Proxy

  def self.data_for_select2
    Menu.includes(:***REMOVED***_type).ordered.group_by(&:***REMOVED***_type).map do |***REMOVED***_type, ***REMOVED***s|
      {
        name: ***REMOVED***_type.to_s,
        children: ***REMOVED***s.map { |s| { id: s.id, name: s.to_s, text: s.to_s } }
      }
    end.to_json
  end
end
