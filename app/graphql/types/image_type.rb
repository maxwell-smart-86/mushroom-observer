module Types
  class ImageType < Types::BaseObject
    field :id, ID, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: true
    field :content_type, String, null: true
    field :user_id, Integer, null: true
    field :user, Types::UserType, null: true
    field :when, GraphQL::Types::ISO8601Date, null: true
    field :notes, String, null: true
    field :copyright_holder, String, null: true
    field :license_id, Integer, null: false
    field :license, Types::LicenseType, null: false
    field :num_views, Integer, null: false
    field :last_view, GraphQL::Types::ISO8601DateTime, null: true
    field :width, Integer, null: true
    field :height, Integer, null: true
    field :vote_cache, Float, null: true
    field :ok_for_export, Boolean, null: false
    field :original_name, String, null: true
    field :transferred, Boolean, null: false
    field :gps_stripped, Boolean, null: false

    field :observations, [Types::ObservationType], null: true
    field :projects, [Types::ProjectType], null: true
    field :glossary_terms, [Types::GlossaryTermType], null: true
    field :best_glossary_terms, [Types::GlossaryTermType], null: true
    field :thumb_clients, [Types::ObservationType], null: true
    field :image_votes, [Types::VoteType], null: true
    field :subjects, [Types::UserType], null: true
    field :copyright_changes, [Types::CopyrightChangeType], null: true
  end
end
