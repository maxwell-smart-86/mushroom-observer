module Types
  class CollectionNumberType < Types::BaseObject
    field :id, ID, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: true
    field :user_id, Integer, null: true
    field :user, Types::UserType, null: true
    field :name, String, null: true
    field :number, String, null: true

    field :observations, [Types::ObservationType], null: true
  end
end
