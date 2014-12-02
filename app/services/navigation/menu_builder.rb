module Navigation
  class MenuBuilder < Base
    def initialize(item, context, user = nil, render = MenuRender)
      super(item, context, render, user)
    end

    def build
      amount_***REMOVED***s
      render
    end

    protected

    def amount_***REMOVED***s
      amount_nodes navigation do |***REMOVED***|
        ***REMOVED***s << ***REMOVED*** if ***REMOVED***[:access].blank? || !@user.student_or_parent?
      end
    end

    def amount_nodes(nodes, parent_***REMOVED*** = nil)
      nodes ||= []

      nodes.each do |node|
        yield node_values(node["***REMOVED***"], parent_***REMOVED***)
      end
    end

    def node_values(node, parent_***REMOVED***)
      {}.tap do |***REMOVED***|
        ***REMOVED***[:type]      = node["type"]
        ***REMOVED***[:icon]      = node["icon"]
        ***REMOVED***[:path]      = node["path"]
        ***REMOVED***[:access]      = node["access"]
        ***REMOVED***[:css_class] = []
        ***REMOVED***[:subnodes]  = []

        if ***REMOVED***[:type] == item
          ***REMOVED***[:css_class] << :current
          parent_***REMOVED***[:css_class] << :open if parent_***REMOVED***
        end

        node["sub***REMOVED***s"] ||= []
        amount_nodes node["sub***REMOVED***s"], ***REMOVED*** do |subnode|
          ***REMOVED***[:subnodes] << subnode
        end
      end
    end

    def render
      navigation_render.render(***REMOVED***s)
    end
  end
end
