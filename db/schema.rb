# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 13) do

  create_table "comments", :force => true do |t|
    t.column "created",        :datetime
    t.column "user_id",        :integer
    t.column "summary",        :string,   :limit => 100
    t.column "comment",        :text
    t.column "observation_id", :integer,                 :default => 0, :null => false
  end

  create_table "images", :force => true do |t|
    t.column "created",          :datetime
    t.column "modified",         :datetime
    t.column "content_type",     :string,   :limit => 100
    t.column "title",            :string,   :limit => 100
    t.column "user_id",          :integer
    t.column "when",             :date
    t.column "notes",            :text
    t.column "copyright_holder", :string,   :limit => 100
  end

  create_table "images_observations", :id => false, :force => true do |t|
    t.column "image_id",       :integer, :default => 0, :null => false
    t.column "observation_id", :integer, :default => 0, :null => false
  end

  create_table "names", :force => true do |t|
    t.column "created",          :datetime
    t.column "modified",         :datetime
    t.column "user_id",          :integer,                                                                                                                   :default => 0, :null => false
    t.column "version",          :integer,                                                                                                                   :default => 0, :null => false
    t.column "rank",             :enum,     :limit => [:Form, :Variety, :Subspecies, :Species, :Genus, :Family, :Order, :Class, :Phyllum, :Kingdom, :Group]
    t.column "text_name",        :string,   :limit => 100
    t.column "author",           :string,   :limit => 100
    t.column "display_name",     :string,   :limit => 200
    t.column "observation_name", :string,   :limit => 200
    t.column "search_name",      :string,   :limit => 200
    t.column "notes",            :text
  end

  create_table "observations", :force => true do |t|
    t.column "created",        :datetime
    t.column "modified",       :datetime
    t.column "when",           :date
    t.column "user_id",        :integer
    t.column "where",          :string,   :limit => 100
    t.column "specimen",       :boolean,                 :default => false, :null => false
    t.column "notes",          :text
    t.column "thumb_image_id", :integer
    t.column "name_id",        :integer
  end

  create_table "observations_species_lists", :id => false, :force => true do |t|
    t.column "observation_id",  :integer, :default => 0, :null => false
    t.column "species_list_id", :integer, :default => 0, :null => false
  end

  create_table "past_names", :force => true do |t|
    t.column "name_id",          :integer
    t.column "created",          :datetime
    t.column "modified",         :datetime
    t.column "user_id",          :integer,                                                                                                                   :default => 0, :null => false
    t.column "version",          :integer,                                                                                                                   :default => 0, :null => false
    t.column "rank",             :enum,     :limit => [:Form, :Variety, :Subspecies, :Species, :Genus, :Family, :Order, :Class, :Phyllum, :Kingdom, :Group]
    t.column "text_name",        :string,   :limit => 100
    t.column "author",           :string,   :limit => 100
    t.column "display_name",     :string,   :limit => 200
    t.column "observation_name", :string,   :limit => 200
    t.column "search_name",      :string,   :limit => 200
    t.column "notes",            :text
  end

  create_table "rss_logs", :force => true do |t|
    t.column "observation_id",  :integer
    t.column "species_list_id", :integer
    t.column "modified",        :datetime
    t.column "notes",           :text
    t.column "name_id",         :integer
  end

  create_table "species_lists", :force => true do |t|
    t.column "created",  :datetime
    t.column "modified", :datetime
    t.column "when",     :date
    t.column "user_id",  :integer
    t.column "where",    :string,   :limit => 100
    t.column "title",    :string,   :limit => 100
    t.column "notes",    :text
  end

  create_table "users", :force => true do |t|
    t.column "login",             :string,   :limit => 80, :default => "",   :null => false
    t.column "password",          :string,   :limit => 40, :default => "",   :null => false
    t.column "email",             :string,   :limit => 80, :default => "",   :null => false
    t.column "theme",             :string,   :limit => 40
    t.column "name",              :string,   :limit => 80
    t.column "created",           :datetime
    t.column "last_login",        :datetime
    t.column "verified",          :datetime
    t.column "feature_email",     :boolean,                :default => true, :null => false
    t.column "commercial_email",  :boolean,                :default => true, :null => false
    t.column "question_email",    :boolean,                :default => true, :null => false
    t.column "rows",              :integer
    t.column "columns",           :integer
    t.column "alternate_rows",    :boolean,                :default => true, :null => false
    t.column "alternate_columns", :boolean,                :default => true, :null => false
    t.column "vertical_layout",   :boolean,                :default => true, :null => false
  end

end
