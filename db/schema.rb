# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 76) do

  create_table "cards", :force => true do |t|
    t.column "tag_id",              :integer,                     :null => false
    t.column "trunk_id",            :integer
    t.column "created_at",          :datetime,                    :null => false
    t.column "value",               :string
    t.column "updated_at",          :datetime,                    :null => false
    t.column "current_revision_id", :integer
    t.column "name",                :string
    t.column "type",                :string,                      :null => false
    t.column "extension_id",        :integer
    t.column "extension_type",      :string
    t.column "sealed",              :boolean,  :default => false
    t.column "created_by",          :integer
    t.column "updated_by",          :integer
    t.column "priority",            :integer,  :default => 0
    t.column "plus_sidebar",        :boolean,  :default => false
    t.column "reader_id",           :integer
    t.column "writer_id",           :integer
    t.column "reader_type",         :string
    t.column "writer_type",         :string
  end

  add_index "cards", ["tag_id", "trunk_id"], :name => "card_parent_id_tag_id_uniq", :unique => true
  add_index "cards", ["name"], :name => "cards_name_index"
  add_index "cards", ["tag_id"], :name => "index_cards_on_tag_id"
  add_index "cards", ["trunk_id"], :name => "index_cards_on_trunk_id"

  create_table "cardtypes", :force => true do |t|
    t.column "class_name", :string
    t.column "system",     :boolean
  end

  add_index "cardtypes", ["class_name"], :name => "cardtypes_class_name_uniq", :unique => true

  create_table "graveyard", :force => true do |t|
    t.column "name",       :string,   :null => false
    t.column "content",    :text
    t.column "created_at", :datetime, :null => false
  end

  create_table "recent_changes", :force => true do |t|
    t.column "card_id",    :integer
    t.column "name",       :string
    t.column "action",     :string,   :null => false
    t.column "editor_id",  :integer,  :null => false
    t.column "note",       :string
    t.column "changed_at", :datetime, :null => false
    t.column "grave_id",   :integer
  end

  create_table "recent_viewings", :force => true do |t|
    t.column "url",       :string,   :null => false
    t.column "card_id",   :integer
    t.column "outcome",   :string,   :null => false
    t.column "viewer_id", :integer
    t.column "viewer_ip", :string
    t.column "viewed_at", :datetime, :null => false
  end

  create_table "revisions", :force => true do |t|
    t.column "created_at", :datetime, :null => false
    t.column "updated_at", :datetime, :null => false
    t.column "card_id",    :integer,  :null => false
    t.column "created_by", :integer,  :null => false
    t.column "content",    :text,     :null => false
  end

  create_table "roles", :force => true do |t|
    t.column "codename", :string
    t.column "tasks",    :string
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.column "role_id", :integer, :null => false
    t.column "user_id", :integer, :null => false
  end

  create_table "sessions", :force => true do |t|
    t.column "session_id", :string
    t.column "data",       :text
    t.column "updated_at", :datetime
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"

  create_table "settings", :force => true do |t|
    t.column "codename", :string
  end

  create_table "system", :force => true do |t|
    t.column "name", :string
  end

  create_table "tag_revisions", :force => true do |t|
    t.column "created_at", :datetime, :null => false
    t.column "tag_id",     :integer,  :null => false
    t.column "created_by", :integer,  :null => false
    t.column "name",       :string,   :null => false
    t.column "updated_at", :datetime, :null => false
  end

  create_table "tags", :force => true do |t|
    t.column "current_revision_id", :integer
    t.column "datatype",            :string,  :default => "string", :null => false
    t.column "label",               :boolean, :default => false
    t.column "card_count",          :integer, :default => 0,        :null => false
    t.column "created_by",          :integer
    t.column "updated_by",          :integer
    t.column "datatype_key",        :string
    t.column "plus_datatype_key",   :string
    t.column "plus_template",       :boolean
  end

  create_table "users", :force => true do |t|
    t.column "login",               :string,   :limit => 40
    t.column "email",               :string,   :limit => 100
    t.column "crypted_password",    :string,   :limit => 40
    t.column "salt",                :string,   :limit => 40
    t.column "created_at",          :datetime
    t.column "updated_at",          :datetime
    t.column "password_reset_code", :string,   :limit => 40
    t.column "blocked",             :boolean,                 :default => false,     :null => false
    t.column "cards_per_page",      :integer,                 :default => 25,        :null => false
    t.column "hide_duplicates",     :boolean,                 :default => true,      :null => false
    t.column "status",              :string,                  :default => "request"
    t.column "invite_sender_id",    :integer
  end

  create_table "wiki_files", :force => true do |t|
    t.column "created_at",  :datetime, :null => false
    t.column "updated_at",  :datetime, :null => false
    t.column "file_name",   :string,   :null => false
    t.column "description", :string,   :null => false
  end

  create_table "wiki_references", :force => true do |t|
    t.column "created_at",         :datetime,                                :null => false
    t.column "updated_at",         :datetime,                                :null => false
    t.column "card_id",            :integer,                 :default => 0,  :null => false
    t.column "referenced_name",    :string,   :limit => nil, :default => "", :null => false
    t.column "referenced_card_id", :integer
    t.column "link_type",          :string,   :limit => 1,   :default => "", :null => false
  end

end
