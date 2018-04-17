
class FollowerStash
  def initialize card=nil
    @followed_affected_cards = Hash.new { |h, v| h[v] = [] }
    @visited = ::Set.new
    add_affected_card(card) if card
  end

  def add_affected_card card
    return if @visited.include? card.key
    Auth.as_bot do
      @visited.add card.key
      notify_direct_followers card
      return if !(left_card = card.left) || @visited.include?(left_card.key) ||
                !(follow_field_rule = left_card.rule_card(:follow_fields))
      follow_field_rule.item_names(context: left_card.name).each do |item|
        if @visited.include? item.to_name.key
          add_affected_card left_card
          break
        elsif item.to_name.key == Card[:includes].key
          includee_set = Card.search(
            { included_by: left_card.name },
            "follow cards included by #{left_card.name}"
          ).map(&:key)
          unless @visited.intersection(includee_set).empty?
            add_affected_card left_card
            break
          end
        end
      end
    end
  end

  def followers
    @followed_affected_cards.keys
  end

  def each_follower_with_reason
    # "follower"(=user) is a card object, "followed"(=reasons) a card name
    @followed_affected_cards.each do |user, reasons|
      yield(user, reasons.first)
    end
  end

  private

  def notify_direct_followers card
    card.all_direct_follower_ids_with_reason do |user_id, reason|
      notify Card.fetch(user_id), of: reason
    end
  end

  def notify follower, because
    @followed_affected_cards[follower] << because[:of]
  end
end

def act_card
  @supercard || self
end

def followable?
  true
end

def silent_change
  @silent_change || (@supercard && @supercard.silent_change)
end

def silent_change?
  silent_change
end

event :only_notify_on_web_requests, :initialize,
      when: proc { !Card::Env[:controller] } do
  @silent_change = true
end

def notable_change?
  !silent_change? && current_act_card? &&
    Card::Auth.current_id != WagnBotID && followable?
end

def current_act_card?
  return false unless (act_card = ActManager.act_card)
  act_card.id.nil? || act_card.id == id
  # FIXME: currently card_id is nil for deleted acts (at least
  # in the store phase when it's tested).  The nil test was needed
  # to make this work.
end

event :notify_followers_after_save,
      :integrate_with_delay, on: :save, when: :notable_change? do
  notify_followers
end

# in the delete case we have to calculate the follower_stash beforehand
# but we can't pass the follower_stash through the ActiveJob queue.
# We have to deal with the notifications in the integrate phase instead of the
# integrate_with_delay phase
event :stash_followers, :store,
      on: :delete, when: proc { |ca| ca.notable_change? } do
  act_card.follower_stash ||= FollowerStash.new
  act_card.follower_stash.add_affected_card self
end

event :notify_followers_after_delete, :integrate,
      on: :delete, when: proc { |ca|  ca.notable_change? } do
  notify_followers
end

def notify_followers
  act = ActManager.act
  act.reload
  act_followers(act).each_follower_with_reason do |follower, reason|
    next if !follower.account || (follower == act.actor)
    follower.account.send_change_notice act, reason[:set_card].name, reason[:option]
  end
# this error handling should apply to all extend callback exceptions
rescue => e
  Rails.logger.info "\nController exception: #{e.message}"
  Card::Error.current = e
  notable_exception_raised
end

def act_followers act
  @follower_stash ||= FollowerStash.new
  act.actions.each do |a|
    next if !a.card || a.card.silent_change?
    @follower_stash.add_affected_card a.card
  end
  @follower_stash
end

format do
  view :list_of_changes, denial: :blank, cache: :never do
    action = notification_action voo.action_id
    relevant_fields(action).map do |type|
      edit_info_for(type, action)
    end.compact.join
  end

  def relevant_fields action
    case action.action_type
    when :create then
      %i[cardtype content]
    when :update then
      %i[name cardtype content]
    when :delete then
      [:content]
    end
  end

  view :subedits, perms: :none, cache: :never do
    wrap_subedits do
      notification_act.actions_affecting(card).map do |action|
        next if action.card_id == card.id
        action.card.format(format: @format).render_subedit_notice action_id: action.id
      end
    end
  end

  view :subedit_notice do
    action = notification_action voo.action_id
    wrap_subedit_item do
      %(#{name_before_action action} #{action.action_type}d\n) +
        render_list_of_changes(action_id: action.id)
    end
  end

  def name_before_action action
    (action.value(:name) && action.previous_value(:name)) || card.name
  end

  def followed_set_card
    (set_name = active_notice(:followed_set)) && Card.fetch(set_name)
  end

  def follow_option_card
    (option_name = active_notice(:follow_option)) &&
      Card.fetch(option_name)
  end

  def active_notice key
    return unless (@active_notice ||= inherit(:active_notice))
    @active_notice[key]
  end

  view :followed, perms: :none, closed: true do
    if (set_card = followed_set_card) &&
       (option_card = follow_option_card)
      option_card.description set_card
    else
      "*followed set of cards*"
    end
  end

  view :follower, perms: :none, closed: true do
    active_notice(:follower) || "follower"
  end

  def live_follow_rule_name
    return unless (set_card = followed_set_card) && (follower = active_notice(:follower))
    set_card.follow_rule_name follower
  end

  view :unfollow_url, perms: :none, closed: true, cache: :never do
    return "" unless (rule_name = live_follow_rule_name)
    target_name = "#{active_notice(:follower)}+#{Card[:follow].name}"
    update_path = page_path target_name, action: :update,
                            card: { subcards: {
                                rule_name => Card[:never].name
                            } }
    card_url update_path # absolutize path
  end

  def edit_info_for field, action
    return nil unless action.value field

    item_title =
      case action.action_type
      when :update then "new "
      when :delete then "deleted "
      else ""
      end
    item_title += "#{field}: "
    item_value =
      if action.action_type == :delete
        action.previous_value field
      else
        action.value field
      end

    wrap_list_item "#{item_title}#{item_value}"
  end

  def wrap_subedits
    subedits = yield.compact.join
    return "" if subedits.blank?
    "\nThis update included the following changes:#{wrap_list subedits}"
  end

  def wrap_list list
    "\n#{list}\n"
  end

  def wrap_list_item item
    "   #{item}\n"
  end

  def wrap_subedit_item
    "\n#{yield}\n"
  end

  def notification_act act=nil
    @notification_act ||= act || card.acts.last
  end

  def notification_action action_id
    action_id ? Action.fetch(action_id) : card.last_action
  end

  view :last_action_verb, cache: :never do
    "#{notification_act.main_action.action_type}d"
  end
end

format :email_text do
  view :last_action, perms: :none, cache: :never do
    _render_last_action_verb
  end
end

format :email_html do
  view :last_action, perms: :none, cache: :never do
    _render_last_action_verb
  end

  def wrap_list list
    "<ul>#{list}</ul>\n"
  end

  def wrap_list_item item
    "<li>#{item}</li>\n"
  end

  def wrap_subedit_item
    "<li>#{yield}</li>\n"
  end
end
