def ok_to_read
  true
end

format :html do
  view :core, cache: :never do
    status_class = Auth.signed_in? ? "logged-in" : "logged-out"
    wrap_with :span, id: "logging", class: status_class do
      item_links.join " "
    end
  end

  def item_links _args=nil
    # removed invite for now
    %i[my_card sign_out sign_up sign_in].map do |link_view|
      render link_view
    end.compact
  end

  def self.link_options opts={}
    options = { denial: :blank, cache: :never }.merge opts
    options[:perms] = ->(r) { yield r } if block_given?
    options.clone
  end

  view :sign_up, link_options(&:show_signup_link?) do
    link_to_card :signup, account_link_text(:sign_up),
                 class: nav_link_class("signup-link"),
                 path: { action: :new, mark: :signup }
  end

  view( :sign_in, link_options { !Auth.signed_in? }) do
    link_to_card :signin, account_link_text(:sign_in),
                 class: nav_link_class("signin-link")
  end

  view(:sign_out, link_options { Auth.signed_in? }) do
    link_to_card :signin, account_link_text(:sign_out),
                 class: nav_link_class("signout-link"),
                 path: { action: :delete }
  end

  view :invite, link_options(&:show_invite_link?) do
    link_to_card :signup, account_link_text(:invite),
                 class: nav_link_class("invite-link"),
                 path: { action: :new, mark: :signup }
  end

  view(:my_card, link_options { Auth.signed_in? }) do
    link = link_to_card Auth.current.name, nil,
                        id: "my-card-link",
                        class: nav_link_class("my-card")
    role_view = roles.size > 1 ? :link_with_checkbox : :link
    split_button link, nil do
      [
        link_to_card([Auth.current, :account_settings], "Account"),
        ["Roles", (roles.map { |r| nest r, view: role_view })]
      ]
    end
  end

  def roles
    @roles ||= [Card[:eagle], Auth.current.fetch(trait: :roles)&.item_names].flatten.compact
  end

  def account_link_text purpose
    voo.title ||
      I18n.t(purpose, scope: "mod.account.set.self.account_links")
  end

  def nav_link_class type
    "nav-link #{classy(type)}"
  end

  def show_signup_link?
    !Auth.signed_in? && Card.new(type_id: Card::SignupID).ok?(:create)
  end

  def show_invite_link?
    Auth.signed_in? &&
      Card.new(type_id: Card.default_accounted_type_id).ok?(:create)
  end
end
