module Navigation
  class ShortcutsBuilder
    def self.build(*args)
      new(*args).build
    end

    def initialize(user, render = ShortcutRender)
      @navigation_render = render.new(user)
      @navigation = Navigation::Base::MENU
    end

    def build
      shortcuts = amount_nodes(navigation).compact.flatten
      navigation_render.render(shortcuts)
    end

    protected

    attr_reader :navigation, :navigation_render

    def amount_nodes(nodes)
      nodes.map { |node|
        next unless node['menu']['shortcut']

        node_values(node['menu'])
      }
    end

    def node_values(node)
      if node['submenus']
        node['submenus'].
          select { |submenu| submenu['menu']['shortcut'] }.
          map { |submenu| submenu['menu'].merge(node.slice('icon')) }
      else
        node.slice('type', 'icon', 'path')
      end
    end
  end
end
