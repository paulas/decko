# -*- encoding : utf-8 -*-

class Card
  class Action < ActiveRecord::Base
    belongs_to :card
    belongs_to :act,  foreign_key: :card_act_id, inverse_of: :actions
    has_many :card_changes, foreign_key: :card_action_id, inverse_of: :action,
                            dependent: :delete_all, class_name: 'Card::Change'

    belongs_to :super_action, class_name: 'Action', inverse_of: :sub_actions
    has_many :sub_actions, class_name: 'Action', inverse_of: :super_action

    scope :created_by, lambda { |actor_id|
                         joins(:act).where 'card_acts.actor_id = ?', actor_id
                       }

    # replace with enum if we start using rails 4
    TYPE = [:create, :update, :delete].freeze

    def expire
      self.class.cache.delete id.to_s
    end

    after_save :expire

    class << self
      def cache
        Card::Cache[Action]
      end

      def fetch id
        cache.read(id.to_s) || begin
          cache.write id.to_s, Action.find(id.to_i)
        end
      end

      def delete_cardless
        left_join = 'LEFT JOIN cards ON card_actions.card_id = cards.id'
        Card::Action.joins(left_join).where('cards.id IS NULL').delete_all
      end

      def delete_old
        Card.find_each(&:delete_old_actions)
        Card::Act.delete_actionless
      end
    end

    #
    # This is the main API from Cards to history
    # See also create_act_and_action, which needs to happen before this or we
    # don't have the action to call this method on.
    #
    # When changes are stored for versioned attributes, this is the signal
    # method. By overriding this method in a module, the module takes over
    # handling of changes.  Although the standard version stores the Changes in
    # ActiveRecord models (Act, Action and Change records), these could be
    # /dev/nulled for a history-less implementation, or handled by an external
    # service.
    #
    # If change streams are generated from database triggers, and we aren't
    # writing here (disabled history), we still have to generate change stream
    # events in another way.

    def changed_fields obj, changed_fields
      changed_fields.each do |f|
        Card::Change.create field: f, value: obj[f], card_action_id: id
      end
    end

    def edit_info
      @edit_info ||= {
        action_type:  "#{action_type}d",
        new_content:  new_values[:content],
        new_name:     new_values[:name],
        new_cardtype: new_values[:cardtype],
        old_content:  old_values[:content],
        old_name:     old_values[:name],
        old_cardtype: old_values[:cardtype]
      }
    end

    def new_values
      @new_values ||=
        {
          content:  new_value_for(:db_content),
          name:     new_value_for(:name),
          cardtype: ((typecard = Card[new_value_for(:type_id).to_i]) &&
                     typecard.name.capitalize)
        }
    end

    def old_values
      @old_values ||= {
        content:  last_value_for(:db_content),
        name:     last_value_for(:name),
        cardtype: ((value = last_value_for(:type_id)) &&
                   (typecard = Card.find(value)) &&
                   typecard.name.capitalize)
      }
    end

    def last_value_for field
      ch = card.last_change_on(field, before: self)
      ch && ch.value
    end

    def field_index field
      if field.is_a? Integer
        field
      else
        Card::TRACKED_FIELDS.index(field.to_s)
      end
    end

    def new_value_for field
      ch = card_changes.find_by(field: field_index(field))
      ch && ch.value
    end

    def change_for field
      card_changes.where 'card_changes.field = ?', field_index(field)
    end

    def new_type?
      new_value_for :type_id
    end

    def new_content?
      new_value_for :db_content
    end

    def new_name?
      new_value_for :name
    end

    def action_type= value
      write_attribute :action_type, TYPE.index(value)
    end

    def action_type
      TYPE[read_attribute(:action_type)]
    end

    def set_act
      self.set_act ||= acts.last
    end

    def revision_nr
      card.actions.index_of self
    end

    def red?
      content_diff_builder.red?
    end

    def green?
      content_diff_builder.green?
    end

    # def diff
    #   @diff ||= { cardtype: type_diff, content: content_diff, name: name_diff}
    # end

    def name_diff opts={}
      return unless new_name?
      Card::Diff.complete old_values[:name], new_values[:name], opts
    end

    def cardtype_diff opts={}
      return unless new_type?
      Card::Diff.complete old_values[:cardtype], new_values[:cardtype], opts
    end

    def content_diff diff_type=:expanded, opts=nil
      return unless new_content?
      if diff_type == :summary
        content_diff_builder(opts).summary
      else
        content_diff_builder(opts).complete
      end
    end

    def content_diff_builder opts=nil
      @content_diff_builder ||= begin
        diff_args = opts || card.include_set_modules.diff_args
        Card::Diff::Builder.new(
          old_values[:content], new_values[:content], diff_args
        )
      end
    end

    def card
      Card.fetch card_id, look_in_trash: true
    end
  end
end
