module Navigation
  class TitleRender < Navigation::Render::Base
    def render(params, show_icon)
      html = []

      html << render_icon(params) if show_icon

      html << render_title(params)

      raw html.join(" ")
    end

    protected

    def render_icon(params)
      content_tag(:i, "", :class => "fa fa-fw #{params[:icon]}")
    end

    def render_title(params)
      I18n.t(params[:type], :scope => :navigation)
    end
  end
end
