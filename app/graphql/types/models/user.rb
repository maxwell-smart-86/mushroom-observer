module Types::Models
  class User < Types::BaseObject
    field :id, ID, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: true
    field :last_login, GraphQL::Types::ISO8601DateTime, null: true
    field :last_activity, GraphQL::Types::ISO8601DateTime, null: true
    field :verified, GraphQL::Types::ISO8601DateTime, null: true
    field :login, String, null: false
    field :name, String, null: true
    field :email, String, null: false
    field :password, String, null: false
    field :admin, Boolean, null: true
    field :alert, String, null: true
    field :auth_code, String, null: true
    field :mailing_address, String, null: true
    field :notes, String, null: true
    field :notes_template, String, null: true
    field :theme, String, null: true
    field :thumbnail_size, Integer, null: true
    field :image_size, Integer, null: true
    field :default_rss_type, String, null: true
    field :location_format, Integer, null: true
    field :hide_authors, Integer, null: false
    field :thumbnail_maps, Boolean, null: false
    field :keep_filenames, Integer, null: false
    field :layout_count, Integer, null: true
    field :view_owner_id, Boolean, null: false
    field :view_owner, Types::Models::User, null: false
    field :content_filter, String, null: true
    field :license_id, Integer, null: false
    field :license, Types::Models::License, null: false
    field :image_id, Integer, null: true
    field :image, Types::Models::Image, null: true
    field :location_id, Integer, null: true
    field :location, Types::Models::Location, null: true
    field :locale, String, null: true
    field :votes_anonymous, Integer, null: true
    field :bonuses, String, null: true
    field :contribution, Integer, null: true
    field :email_comments_owner, Boolean, null: false
    field :email_comments_response, Boolean, null: false
    field :email_comments_all, Boolean, null: false
    field :email_observations_consensus, Boolean, null: false
    field :email_observations_naming, Boolean, null: false
    field :email_observations_all, Boolean, null: false
    field :email_names_author, Boolean, null: false
    field :email_names_editor, Boolean, null: false
    field :email_names_reviewer, Boolean, null: false
    field :email_names_all, Boolean, null: false
    field :email_locations_author, Boolean, null: false
    field :email_locations_editor, Boolean, null: false
    field :email_locations_all, Boolean, null: false
    field :email_general_feature, Boolean, null: false
    field :email_general_commercial, Boolean, null: false
    field :email_general_question, Boolean, null: false
    field :email_html, Boolean, null: false
    field :email_locations_admin, Boolean, null: true
    field :email_names_admin, Boolean, null: true

    # Relationship fields has_many
    field :api_keys, [Types::Models::ApiKey], null: true
    field :comments, [Types::Models::Comment], null: true
    field :donations, [Types::Models::Donation], null: true
    field :external_links, [Types::Models::ExternalLink], null: true
    field :images, [Types::Models::Image], null: true
    field :interests, [Types::Models::Interest], null: true
    field :locations, [Types::Models::Location], null: true
    # field :location_descriptions, [Types::Models::LocationDescription], null: true
    field :names, [Types::Models::Name], null: true
    # field :name_descriptions, [Types::Models::NameDescription], null: true
    field :namings, [Types::Models::Naming], null: true
    field :notifications, [Types::Models::Notification], null: true
    field :observations, [Types::Models::Observation], null: true
    field :projects_created, [Types::Models::Project], null: true
    field :publications, [Types::Models::Publication], null: true
    # field :queued_emails, [Types::QueuedEmail], null: true
    field :sequences, [Types::Models::Sequence], null: true
    field :species_lists, [Types::Models::SpeciesList], null: true
    field :herbarium_records, [Types::Models::HerbariumRecord], null: true
    field :votes, [Types::Models::Vote], null: true
    field :reviewed_images, [Types::Models::Image], null: true
    # field :reviewed_name_descriptions, [Types::Models::NameDescription], null: true
    # field :to_emails, [Types::Models::QueuedEmail], null: true
    field :user_groups, [Types::Models::UserGroup], null: true
    # field :authored_names, [Types::Models::NameDescription], null: true
    # field :edited_names, [Types::Models::NameDescription], null: true
    # field :authored_locations, [Types::Models::LocationDescription], null: true
    # field :edited_locations, [Types::Models::LocationDescription], null: true
    field :curated_herbaria, [Types::Models::Herbarium], null: true
  end
end
