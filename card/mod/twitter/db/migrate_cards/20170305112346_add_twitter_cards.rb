# -*- encoding : utf-8 -*-

class AddTwitterCards < Card::Migration
  def up
    ensure_card name: "Twitter template", codename: "twitter_template",
                type_id: Card::CardtypeID
    ensure_card name: "*message", codename: "message"
    [:consumer ]
    [["*consumer key", "consumer_key"],
     ["*consumer secret", "consumer_secret"],
     ["*access token", "access_token"],
     ["*access secret", "access_secret"]].each do |name, key|
      ensure_card name, codename: key
      ensure_card [name, :right, :default], type_id: Card::PhraseID
      ensure_card [name, :right, :read], content: "[[Administrator]]"
    end

    Card::Cache.reset_all

    ensure_card name: [:twitter_template, :type, :structure],
                content: structure
  end

  def structure
    ["*message", "*consumer key", "*consumer secret", "*access token",
     "*access secret"].map do |name|
      "{{+#{name}}}"
    end.join "\n"
  end
end
