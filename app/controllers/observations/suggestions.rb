# frozen_string_literal: true

# see observations_controller.rb
class ObservationsController
  helper SuggestionsHelper
  def suggestions
    @observation = find_or_goto_index(Observation, params[:id].to_s)
    @suggestions = Suggestion.analyze(JSON.parse(params[:names].to_s))
  end
end
