module Navigation
  def self.draw_breadcrumbs(item, context)
    BreadcrumbsBuilder.build(item, context)
  end

  def self.draw_menus(item, user)
    MenuBuilder.build(item, user)
  end

  def self.draw_title(item, show_icone, context)
    TitleBuilder.build(item, show_icone, context)
  end

  def self.draw_shortcuts(user)
    ShortcutsBuilder.build(user)
  end
end
