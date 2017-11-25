# Controls viewing and modifying herbarium records.
class HerbariumRecordController < ApplicationController
  before_action :login_required, except: [
    :index_herbarium_record,
    :list_herbarium_records,
    :herbarium_record_search,
    :herbarium_index,
    :observation_index,
    :show_herbarium_record
  ]

  # ----------------------------
  #  Indexes
  # ----------------------------

  # Displays matrix of selected HerbariumRecord's (based on current Query).
  def index_herbarium_record # :nologin: :norobots:
    query = find_or_create_query(:HerbariumRecord, by: params[:by])
    show_selected_herbarium_records(query, id: params[:id].to_s,
                                           always_index: true)
  end

  # Show list of herbarium_records.
  def list_herbarium_records # :nologin:
    store_location
    query = create_query(:HerbariumRecord, :all, by: :herbarium_label)
    show_selected_herbarium_records(query)
  end

  # Display list of HerbariumRecords whose text matches a string pattern.
  def herbarium_record_search # :nologin: :norobots:
    pattern = params[:pattern].to_s
    if pattern.match(/^\d+$/) &&
       (herbarium_record = HerbariumRecord.safe_find(pattern))
      redirect_to(action: :show_herbarium_record, id: herbarium_record.id)
    else
      query = create_query(:HerbariumRecord, :pattern_search, pattern: pattern)
      show_selected_herbarium_records(query)
    end
  end

  def herbarium_index # :nologin:
    store_location
    query = create_query(:HerbariumRecord, :in_herbarium,
                         herbarium: params[:id].to_s, by: :herbarium_label)
    show_selected_herbarium_records(query, always_index: true)
  end

  def observation_index # :nologin:
    store_location
    query = create_query(:HerbariumRecord, :for_observation,
                         observation: params[:id].to_s, by: :herbarium_label)
    @links = [
      [:show_object.l(type: :observation),
        Observation.show_link_args(params[:id])],
      [:add_herbarium_record.l,
        { action: :add_herbarium_record, id: params[:id] }]
    ]
    show_selected_herbarium_records(query, always_index: true)
  end

  # Show selected list of herbarium_records.
  def show_selected_herbarium_records(query, args = {})
    args = {
      action: :list_herbarium_records,
      letters: "herbarium_records.initial_det",
      num_per_page: 100
    }.merge(args)

    @links ||= []
    @links << [:create_herbarium.l,
               { controller: :herbarium, action: :create_herbarium }]

    # Add some alternate sorting criteria.
    args[:sorting_links] = [
      ["herbarium_name",  :sort_by_herbarium_name.t],
      ["herbarium_label", :sort_by_herbarium_label.t],
      ["created_at",      :sort_by_created_at.t],
      ["updated_at",      :sort_by_updated_at.t]
    ]

    show_index_of_objects(query, args)
  end

  # ----------------------------
  #  Show record
  # ----------------------------

  def show_herbarium_record  # :nologin:
    store_location
    pass_query_params
    @layout = calc_layout_params
    @canonical_url = HerbariumRecord.show_url(params[:id])
    @herbarium_record = find_or_goto_index(HerbariumRecord, params[:id])
  end

  def next_herbarium_record # :nologin: :norobots:
    redirect_to_next_object(:next, HerbariumRecord, params[:id].to_s)
  end

  def prev_herbarium_record # :nologin: :norobots:
    redirect_to_next_object(:prev, HerbariumRecord, params[:id].to_s)
  end

  # ----------------------------
  #  Create record
  # ----------------------------

  def create_herbarium_record
    pass_query_params
    @layout      = calc_layout_params
    @observation = find_or_goto_index(Observation, params[:id])
    return if !@observation
    if request.method == "GET"
      @herbarium_record = default_herbarium_record
    elsif request.method == "POST"
      post_create_herbarium_record
    else
      redirect_back_or_default("/")
    end
  end

  def edit_herbarium_record # :norobots:
    pass_query_params
    @layout = calc_layout_params
    @herbarium_record = find_or_goto_index(HerbariumRecord, params[:id])
    return unless @herbarium_record
    return unless make_sure_can_edit!
    if request.method == "GET"
      @herbarium_record.herbarium_name = @herbarium_record.herbarium.try(&:name)
    elsif request.method == "POST"
      post_edit_herbarium_record
    else
      redirect_back_or_default("/")
    end
  end

  def default_herbarium_record
    HerbariumRecord.new(
      herbarium_name:   @user.preferred_herbarium_name,
      initial_det:      @observation.name.text_name,
      accession_number: "MO #{@observation.id}"
    )
  end

  def post_create_herbarium_record
    @herbarium_record =
      HerbariumRecord.new(whitelisted_herbarium_record_params)
    normalize_parameters
    if !validate_herbarium_name! ||
       !can_add_record_to_herbarium?
      return
    elsif herbarium_label_free?
      @herbarium_record.save
      @herbarium_record.add_observation(@observation)
    elsif @other_record.can_edit?
      flash_warning(:create_herbarium_record_already_used.t)
      @other_record.add_observation(@observation)
    else
      flash_error(:create_herbarium_record_already_used_by_someone_else.
        t(herbarium_name: @herbarium_record.herbarium.name))
      return
    end
    redirect_to_observation_or_herbarium_record
  end

  def post_edit_herbarium_record
    old_herbarium = @herbarium_record.herbarium
    @herbarium_record.attributes = whitelisted_herbarium_record_params
    normalize_parameters
    if !validate_herbarium_name! ||
       !can_add_record_to_herbarium?
      return
    elsif herbarium_label_free?
      @herbarium_record.save
      @herbarium_record.notify_curators if
        @herbarium_record.herbarium != old_herbarium
    else
      flash_warning(:edit_herbarium_record_already_used.t)
      return
    end
    redirect_to_observation_or_herbarium_record
  end

  def make_sure_can_edit!
    return true if in_admin_mode? || @herbarium_record.can_edit?
    return true if @herbarium_record.herbarium.curators.include?(@user)
    flash_error :permission_denied.t
    redirect_to_observation_or_herbarium_record
    false
  end

  def normalize_parameters
    [:herbarium_name, :initial_det, :accession_number].each do |arg|
      val = @herbarium_record.send(arg).to_s.strip_html.strip_squeeze
      @herbarium_record.send("#{arg}=", val)
    end
    @herbarium_record.notes = @herbarium_record.notes.to_s.strip
  end

  def validate_herbarium_name!
    name = @herbarium_record.herbarium_name
    @herbarium_record.herbarium = Herbarium.where(name: name).first
    if name.blank?
      flash_error(:create_herbarium_record_missing_herbarium_name.t)
      return false
    elsif !@herbarium_record.herbarium.nil?
      return true
    elsif name != @user.personal_herbarium_name || @user.personal_herbarium
      flash_warning(:create_herbarium_separately.t)
      return false
    else
      @herbarium_record.herbarium = @user.create_personal_herbarium
      return true
    end
  end

  def can_add_record_to_herbarium?
    return true if @observation && @observation.can_edit?
    return true if @herbarium_record.observations.any?(&:can_edit?)
    return true if @herbarium_record.herbarium.is_curator?(@user)
    flash_error(:create_herbarium_record_only_curator_or_owner.t)
    redirect_to_observation_or_herbarium_record
    return false
  end

  def herbarium_label_free?
    @other_record = HerbariumRecord.where(
      herbarium:        @herbarium_record.herbarium,
      accession_number: @herbarium_record.accession_number
    ).first
    !@other_record || @other_record == @herbarium_record
  end

  def redirect_to_observation_or_herbarium_record
    if @observation
      redirect_with_query(@observation.show_link_args)
    elsif @herbarium_record.observations.count == 1
      redirect_with_query(@herbarium_record.observations.first.show_link_args)
    else
      redirect_with_query(@herbarium_record.show_link_args)
    end
  end

  # ----------------------------
  #  Delete record
  # ----------------------------

  def remove_observation
    herbarium_record = find_or_goto_index(HerbariumRecord, params[:id])
    return unless herbarium_record
    observation = find_or_goto_index(Observation, params[:obs])
    return unless observation
    return unless make_sure_can_delete!(herbarium_record)
    herbarium_record.observations.delete(observation)
    herbarium_record.destroy if herbarium_record.observations.empty?
    redirect_to(observation.show_link_args)
  end

  def destroy_herbarium_record
    herbarium_record = find_or_goto_index(HerbariumRecord, params[:id])
    return unless herbarium_record
    return unless make_sure_can_delete!(herbarium_record)
    herbarium_record.destroy
    redirect_to(action: :index_herbarium_record)
  end

  def make_sure_can_delete!(herbarium_record)
    return true if in_admin_mode? || herbarium_record.can_edit?
    return true if herbarium_record.herbarium.curators.include?(@user)
    flash_error(:permission_denied.t)
    redirect_to(herbarium_record.show_link_args)
    return false
  end

  ##############################################################################

  private

  def whitelisted_herbarium_record_params
    return {} unless params[:herbarium_record]
    params.require(:herbarium_record).
           permit(:herbarium_name, :initial_det, :accession_number, :notes)
  end
end
