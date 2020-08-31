# frozen_string_literal: true

#  Controller for nucleotide Sequences
#
#  Actions:
#
#    index_sequence::    List selected sequences, based on current Query.
#    show_sequence::     Display sequence details.
#    create_sequence::   Create new sequence and add to Observation.
#    destroy_sequence::  Destroy sequence.
#    edit_sequence::     Update sequence.
#
# NIMMO NOTE!!!! PARAM FOR SEQUENCE OBSERVATION HAS CHANGED FROM :id TO :obs !!!
# MUST CHANGE ALSO IN TESTS!!! - 08/20

class SequencesController < ApplicationController
  before_action :login_required, except: [
    :index,
    :show,
    # :index_sequence,
    # :sequence_search,
    # :observation_index,
    # :show_next,
    # :show_prev
    # :list_sequences, # aliased
    # :show_sequence, # aliased
    # :next_sequence, # aliased
    # :prev_sequence # aliased
  ]

  def index
    puts "-" * 80
    puts "We are in sequences_controller index"
    puts "-" * 80
    store_location
    if params[:obs]
      observation_index
    elsif params[:pattern]
      search
    elsif params[:q] || params[:by]
      index_sequence
    else
      query = create_query(:Sequence, :all)
      show_selected_sequences(query)
    end
  end

  alias :list_sequences :index

  def show
    puts "-" * 80
    puts "We are in sequences_controller show"
    puts "-" * 80

    pass_query_params
    store_location

    if params[:next]
      redirect_to_next_object(:next, Sequence, params[:id].to_s)
    elsif params[:prev]
      redirect_to_next_object(:prev, Sequence, params[:id].to_s)
    else
      @sequence = find_or_goto_index(Sequence, params[:id].to_s)
    end
  end

  alias :show_sequence :show

  def new
    puts "-" * 80
    puts "We are in sequences_controller new"
    puts "-" * 80

    store_location
    pass_query_params
    @observation = find_or_goto_index(Observation, params[:obs].to_s)
    return unless @observation

    @back_object = @observation
    @sequence = Sequence.new(observation: @observation)
  end

  alias :create_sequence :new

  def create
    puts "-" * 80
    puts "We are in sequences_controller create"
    puts "-" * 80

    store_location
    pass_query_params
    @observation = find_or_goto_index(Observation, params[:obs].to_s)
    # byebug
    return unless @observation

    build_sequence
  end

  def edit
    puts "-" * 80
    puts "We are in sequences_controller edit"
    puts "-" * 80

    store_location
    pass_query_params
    @sequence = find_or_goto_index(Sequence, params[:id].to_s)
    return unless @sequence

    figure_out_where_to_go_back_to
    if !check_permission(@sequence)
      flash_warning(:permission_denied.t)
      redirect_to observation_path(@sequence.observation_id, q: get_query_param)
    end
  end

  alias edit_sequence edit

  def update
    puts "-" * 80
    puts "We are in sequences_controller update"
    puts "-" * 80

    store_location
    pass_query_params
    @sequence = find_or_goto_index(Sequence, params[:id].to_s)
    return unless @sequence

    figure_out_where_to_go_back_to
    if check_permission(@sequence)
      save_updates
    else
      flash_warning(:permission_denied.t)
      redirect_to(observation_path(@sequence.observation, q: params[:q]))
    end
  end

  def destroy
    puts "-" * 80
    puts "We are in sequences_controller destroy"
    puts "-" * 80

    pass_query_params
    @sequence = find_or_goto_index(Sequence, params[:id].to_s)
    return unless @sequence

    figure_out_where_to_go_back_to
    if check_permission(@sequence)
      @sequence.destroy
      flash_notice(:runtime_destroyed_id.t(type: Sequence, value: params[:id]))
    else
      flash_warning(:permission_denied.t)
    end

    if @back == "index"
      # redirect_with_query(action: :index_sequence)
      redirect_to sequences_path(q: get_query_param)
    else
      redirect_to(helpers.object_path(@back_object, q: get_query_param))
    end
  end

  alias :destroy_sequence :destroy

  ##############################################################################

  private

  def index_sequence
    query = find_or_create_query(:Sequence, by: params[:by])
    show_selected_sequences(query, id: params[:id].to_s, always_index: true)
  end

  # Display list of Sequences whose text matches a string pattern.
  def search
    puts "-" * 80
    puts "We are in sequences_controller search"
    puts "-" * 80

    pattern = params[:pattern].to_s
    if pattern.match?(/^\d+$/) &&
       (@sequence = Sequence.safe_find(pattern))
      puts "-" * 80
      puts @sequence.inspect
      puts "-" * 80
      redirect_to sequence_path(@sequence.id)
      return
    else
      puts "-" * 80
      puts "sequences_controller: I'm sensing a pattern"
      puts "-" * 80
      query = create_query(:Sequence, :pattern_search, pattern: pattern)
      show_selected_sequences(query)
    end
  end

  # Note: This action now needs params[:obs] instead of params[:id]
  # to differentiate the request from other requests hitting the index - AN
  def observation_index
    store_location
    query = create_query(:Sequence, :for_observation,
                         observation: params[:obs].to_s)
    @links = []
    @links << [:show_object.l(type: :observation),
              observation_path(params[:obs])]
    @links << [:show_observation_add_sequence.l,
              new_sequence_path(obs: params[:obs])]
    show_selected_sequences(query, always_index: true)
  end

  def build_sequence
    puts "-" * 80
    puts "We are in sequences_controller build_sequence"
    pp @query_params
    pp get_query_param
    puts "-" * 80

    @sequence = @observation.sequences.new
    @sequence.attributes = whitelisted_sequence_params
    @sequence.user = @user
    if @sequence.save
      flash_notice(:runtime_sequence_success.t(id: @sequence.id))
      # byebug @query_params[:q] because it's passed via pass_query_params
      redirect_to observation_path(@observation.id, q: get_query_param)
    else
      flash_object_errors(@sequence)
    end
  end

  def save_updates
    puts "-" * 80
    puts "We are in sequences_controller save_updates"
    puts "-" * 80

    @sequence.attributes = whitelisted_sequence_params
    if @sequence.save
      flash_notice(:runtime_sequence_success.t(id: @sequence.id))
      # byebug
      # puts "save_updates saved it, here is the redirect path: "
      # puts helpers.object_path(@back_object, q: get_query_param).to_s
      redirect_to(helpers.object_path(@back_object, q: get_query_param))
    else
      flash_object_errors(@sequence)
    end
  end

  def figure_out_where_to_go_back_to
    @back = params[:back]
    @back_object = @back == "show" ? @sequence : @sequence.observation
  end

  def show_selected_sequences(query, args = {})
    puts "-" * 80
    puts "We are in show_selected_sequences"
    puts "-" * 80

    args = {
      action: :index,
      letters: "sequences.locus",
      num_per_page: 50
    }.merge(args)
    @links ||= []
    args[:sorting_links] = sequence_index_sorts
    show_index_of_objects(query, args)
  end

  def sequence_index_sorts
    [
      ["created_at",  :sort_by_created_at.t],
      ["updated_at",  :sort_by_updated_at.t],
      ["user",        :USER.t],
      ["observation", :OBSERVATION.t]
    ]
  end

  def whitelisted_sequence_params
    params[:sequence].permit(:archive, :accession, :bases, :locus, :notes)
  end
end
