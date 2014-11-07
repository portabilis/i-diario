module Navigation
  class BreadcrumbsBuilder < Builder::Base
    def initialize(item, context, render = BreadcrumbsRender)
      super(item,context, render)
    end

    def build
      find_***REMOVED***s
      render
    end

    protected

    def find_***REMOVED***s
      navigation.each do |node|
        if node["***REMOVED***"]["type"] == item
          ***REMOVED***s << node_values(node["***REMOVED***"])
        elsif node["***REMOVED***"]["sub***REMOVED***s"].present?
           node["***REMOVED***"]["sub***REMOVED***s"].each do |subnode|
            if subnode["***REMOVED***"]["type"] == item
              ***REMOVED***s << node_values(node["***REMOVED***"])
              ***REMOVED***s << node_values(subnode["***REMOVED***"])
            end
          end
        end
      end
    end

    def node_values(node)
      {
        :type => node["type"],
        :icon => node["icon"],
        :path => node["path"]
      }
    end

    def render
      navigation_render.render(***REMOVED***s)
    end
  end
end
