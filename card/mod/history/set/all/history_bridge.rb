
format :html do
  view :creator_credit, wrap: :div, cache: :never do
    "Created by #{nest card.creator, view: :link} #{time_ago_in_words(card.created_at)} ago"
  end

  view :updated_by, wrap: :div, cache: :never do
    updaters = Card.search(updater_of: { id: card.id })
    return "" unless updaters.present?
    "Updated by #{humanized_search_result updaters}"
  end

  view :shorter_pointer_content, cache: :never do
    nest card, view: :shorter_search_result, hide: :link
  end

  def humanized_search_result item_cards, item_view=:link, max_count=3
    return "" unless item_cards.present?
    total = item_cards.size
    fetch_count = total > max_count ? max_count - 1 : max_count

    reduced =
      item_cards.first(fetch_count).map do |c|
        nest c, view: item_view
      end
    reduced << link_to_card(card,  "#{total - fetch_count} others") if total > max_count
    reduced.to_sentence
  end

  def acts_bridge_layout acts, context=:bridge
    bs_layout container: true, fluid: true do
       row(12) { _render_creator_credit }
       row(12) { _render_updated_by }
       row(12) { act_link_list acts, context }
       row(12) { act_paging acts, context }
    end
  end

  def act_link_list acts, context
    act_list_group acts, context do |act, seq|
      act_link_list_item act, seq, context
    end
  end

  def act_link_list_item act, seq=nil, context=nil
    opts = act_listing_opts_from_params(seq)
    opts[:slot_class] = "revision-#{act.id} history-slot list-group-item"
    act_renderer(:bridge).new(self, act, opts).bridge_link
  end

  def act_list_group acts, context, &block
    list_group acts_for_accordion(acts, context, &block), class: "clear-both"
  end

  view :bridge_act, cache: :never do
    opts = act_listing_opts_from_params(nil)
    act = act_from_context
    ar = act_renderer(:bridge).new(self, act, opts)
    wrap_with_overlay title: ar.overlay_title do
      act_listing act, opts[:act_seq], :bridge
    end
  end
end
