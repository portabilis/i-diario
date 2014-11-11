module Navigation
  class BreadcrumbsRender < Navigation::Render::Base
    def render(***REMOVED***s)
      content_tag :ol, :class => 'breadcrumb' do
        items = ***REMOVED***s.map do |***REMOVED***_item|
          render_item(***REMOVED***_item)
        end

        raw items.join(" ")
      end
    end

    protected

    def render_item(params)
      content_tag(:li) do
        link_to path_method(params[:path]) do
          html = []

          if params[:icon]
            html << content_tag(:i, "", :class => "fa #{params[:icon]} fa-fw")
          end

          html << I18n.t(params[:type], :scope => :navigation)

          raw html.join(" ")
        end
      end
    end
  end
end
