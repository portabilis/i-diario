module Navigation
  class BreadcrumbsRender < Navigation::Render::Base
    def render(menus)
      content_tag :ol, :class => 'breadcrumb' do
        items = menus.map do |menu_item|
          render_item(menu_item)
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

          html << Translator.t("navigation.#{params[:type]}")

          raw html.join(" ")
        end
      end
    end
  end
end
