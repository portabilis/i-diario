module Navigation
  class ShortcutRender < Navigation::Render::Base
    def render(menus)
      menu_html = ''

      menus.each_slice(6) do |menu_slice|
        menu_html << content_tag(:div, class: 'row') {
          raw menu_slice.map { |menu| render_menu(menu) }.join(' ')
        }
      end

      raw menu_html
    end

    protected

    def render_menu(menu)
      menu = menu.with_indifferent_access

      return '' unless can_show?(menu[:type])

      content_tag :div, class: 'col-sm-2 text-center shortcut' do
        link_to(path_method(menu[:path])) do
          text = content_tag(:i, '', class: "shortcut-icon fa fa-lg fa-fw #{menu[:icon]}")
          text + content_tag(:span, Translator.t("navigation.#{menu[:type]}"), class: '')
        end
      end
    end
  end
end
