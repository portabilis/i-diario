module Navigation
  class BreadcrumbsBuilder < Base
    def initialize(item, context, render = BreadcrumbsRender)
      super(item,context, render)
      menus << { :type => :begin, :path => "root_path" }
    end

    def build
      find_menus
      render
    end

    protected

    def find_menus
      navigation.each do |node|
        if node["menu"]["type"] == item
          menus << node_values(node["menu"])
        elsif node["menu"]["submenus"].present?
           node["menu"]["submenus"].each do |subnode|
            if subnode["menu"]["type"] == item
              menus << node_values(node["menu"])
              menus << node_values(subnode["menu"])
            end
          end
        end
      end
    end

    def node_values(node)
      return if node['breadcrumb'] == false

      {
        :type => node["type"],
        :icon => node["icon"],
        :path => node["path"]
      }
    end

    def render
      navigation_render.render(menus.compact)
    end
  end
end
