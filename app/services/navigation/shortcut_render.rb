module Navigation
  class ShortcutRender < Navigation::Render::Base
    def render(menus)
      raw menus.map { |menu| render_menu(menu) }.join(' ')
    end

    protected

    def render_menu(menu)
      menu = menu.with_indifferent_access

      return '' unless can_show?(menu[:type])

      content_tag :div, class: 'col-sm-2 text-center shortcut' do
        link_to(path_method(menu[:path])) do
          text = content_tag(:i, '', class: "shortcut-icon fa fa-lg fa-fw #{menu[:icon]}")
          text += content_tag(:span, Translator.t("navigation.#{menu[:type]}"), class: '')
        end
      end
    end

    def can_show?(feature)
      policy(feature).index?
    end

    def policy(feature)
      klass = begin
        feature.singularize.camelcase.constantize
      rescue
        feature
      end

      begin
        Pundit::PolicyFinder.new(klass).policy!.new(current_user, klass)
      rescue
        ApplicationPolicy.new(current_user, klass)
      end
    end
  end
end
