format :html do
  # TODO: use CodeFile cards for these
  # builtin layouts allow for rescue / testing
  HTML_LAYOUTS = Mod::Loader.load_layouts(:html).merge "none" => "{{_main}}"
  HAML_LAYOUTS = Mod::Loader.load_layouts(:haml)

  def show_with_page_layout view, args
    main!
    args = main_render_args view, args
    if explicit_modal_wrapper? view
      render_outside_of_layout view, args
    else
      render_with_layout view, page_layout, args
    end
  end

  def main_render_args view, args
    args[:view] = view if view
    args[:main] = true
    args[:main_view] = true
    args
  end

  def page_layout
    params[:layout] || layout_name_from_rule || :default
  end

  def render_with_layout view, layout, args={}
    view_opts = Layout.main_nest_opts(layout, self)
    view ||= view_opts.delete(:view) || default_nest_view
    view_opts[:layout] = layout
    render! view, view_opts.reverse_merge(args)
  end

  def render_outside_of_layout view, args
    output [
             render_with_layout(nil, page_layout, {}),
             render!(view, args)
           ]
  end

  def show_layout?
    !Env.ajax? || params[:layout]
  end

  def explicit_modal_wrapper? view
    return unless view_setting(:wrap, view)

    wrappers = Array.wrap(view_setting(:wrap, view))
    wrappers.include?(:modal) || wrappers.include?(:bridge)
  end

  def process_haml_layout layout_name
    haml HAML_LAYOUTS[layout_name]
  end

  def process_content_layout layout_name
    content = layout_from_card_or_code layout_name
    process_content content, chunk_list: :references
  end

  def layout_type layout_name
    HAML_LAYOUTS[layout_name.to_s].present? ? :haml : :content
  end

  def layout_name_from_rule
    card.rule_card(:layout)&.try :item_name
  end

  def layout_from_card_or_code name
    layout_card_content(name) || HTML_LAYOUTS[name] || unknown_layout(name)
  end

  def built_in_layouts
    HTML_LAYOUTS.merge(HAML_LAYOUTS).keys.sort.join ", "
  end
end