module Types
  class ObservationViewType < Types::BaseObject
    field :id, ID, null: false
    field :observation_id, Integer, null: true
    field :user_id, Integer, null: true
    field :last_view, GraphQL::Types::ISO8601DateTime, null: true
  end
end
