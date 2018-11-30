module Navigation
  class TitleBuilder < Base
    def initialize(item, show_icon, context, render = TitleRender)
      super(item, context, render)
      @show_icon = show_icon
    end

    def build
      find_title(navigation)
      render
    end

    protected

    attr_reader :show_icon

    def title
      @title ||= {}
    end

    def find_title(nodes, parent_icon = nil)
      nodes.each do |node|
        node = node["menu"]

        if node["type"] == item
          title[:icon] = node["icon"] || parent_icon
          title[:type] = item
        elsif node["submenus"].present?
          find_title node["submenus"], (node["icon"] || parent_icon)
        end
      end
    end

    def render
      navigation_render.render(title, show_icon)
    end
  end
end
