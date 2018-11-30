module Navigation
  class MenuBuilder < Base
    def initialize(item, user, render = MenuRender)
      super(item, user, render)
    end

    def build
      amount_menus
      render
    end

    protected

    def amount_menus
      amount_nodes navigation do |menu|
        menus << menu
      end
    end

    def amount_nodes(nodes, parent_menu = nil)
      nodes ||= []

      nodes.select do |node|
        visible = node["menu"]["visible"]
        next if (!visible.nil? && visible == false) || (visible == 'only-when-active' && node["menu"]["type"] != item)
        yield node_values(node["menu"], parent_menu)
      end
    end

    def node_values(node, parent_menu)
      {}.tap do |menu|
        menu[:type]      = node["type"]
        menu[:icon]      = node["icon"]
        menu[:path]      = node["path"]
        menu[:visible]   = node["visible"]
        menu[:css_class] = []
        menu[:subnodes]  = []

        if menu[:type] == item
          menu[:css_class] << :current
          parent_menu[:css_class] << :open if parent_menu
        end

        node["submenus"] ||= []
        amount_nodes node["submenus"], menu do |subnode|
          menu[:subnodes] << subnode
        end
        true
      end
    end

    def render
      navigation_render.render(menus)
    end
  end
end
