# frozen_string_literal: true

class Name < AbstractModel
  scope :ranked_below,
        ->(rank) { where("`rank` < ?", Name.ranks[rank]) }

  # Is it safe to merge this Name with another? If any information will get
  # lost we return false.  In practice only if it has Namings.
  # UPDATE: I'm also forbidding merges if users have registered interest in
  # or otherwise requested notifications for this name.  In some cases it will
  # be okay, but there are cases where users unintentionally end up subscribed
  # notifications for every name in the database as a side-effect of merging an
  # unwanted name into Fungi, say. -JPH 20200120
  def mergeable?
    namings.empty? && interests_plus_notifications.zero?
  end

  # Is the Name a dependency of another for purposes of merger?
  # (Users should be unable to merge dependencies.)
  def dependency?
    approved_synonym_of_proposed_name? ||
      correctly_spelled_ancestor_of_proposed_name?
  end

  # Merge all the stuff that refers to +old_name+ into +self+.  Usually, no
  # changes are made to +self+, however it might update the +classification+
  # cache if the old name had a better one -- NOT SAVED!!  Then +old_name+ is
  # destroyed; all the things that referred to +old_name+ are updated and
  # saved.
  def merge(old_name)
    return if old_name == self

    xargs = {}

    # Move all observations over to the new name.
    old_name.observations.each do |obs|
      obs.name = self
      obs.save
    end

    # Move all namings over to the new name.
    old_name.namings.each do |name|
      name.name = self
      name.save
    end

    # Move all misspellings over to the new name.
    old_name.misspellings.each do |name|
      name.correct_spelling = name == self ? nil : self
      name.save
    end

    # Move over any interest in the old name.
    Interest.where(
      target_type: "Name", target_id: old_name.id
    ).find_each do |int|
      int.target = self
      int.save
    end

    # Move over any notifications on the old name.
    Notification.where(flavor: Notification.flavors[:name],
                       obj_id: old_name.id).find_each do |note|
      note.obj_id = id
      note.save
    end

    #     # Merge the two "main" descriptions if it can.
    #     if self.description and old_name.description and
    #        (self.description.source_type == :public) and
    #        (old_name.description.source_type == :public)
    #       self.description.merge(old_name.description, true)
    #     end

    # If this one doesn't have a primary description and the other does,
    # then make it this one's.
    if !description && old_name.description
      self.description = old_name.description
    end

    # Update the classification cache if that changed in the process.
    if description &&
       (classification != description.classification)
      self.classification = description.classification
    end

    # Move over any remaining descriptions.
    old_name.descriptions.each do |desc|
      xargs = {
        id: desc,
        set_name: self
      }
      desc.name_id = id
      desc.save
    end

    # Log the action.
    old_name.rss_log&.orphan(old_name.display_name, :log_name_merged,
                             this: old_name.display_name, that: display_name)

    # Destroy past versions.
    editors = []
    old_name.versions.each do |ver|
      editors << ver.user_id
      ver.destroy
    end

    # Update contributions for editors.
    editors.delete(old_name.user_id)
    editors.uniq.each do |user_id|
      SiteData.update_contribution(:del, :names_versions, user_id)
    end

    # Fill in citation if new name is missing one.
    if citation.blank? && old_name.citation.present?
      self.citation = old_name.citation.strip_squeeze
    end

    # Update the identifier if it's blank
    self.icn_id = old_name.icn_id if icn_id.blank?

    # Save any notes the old name had.
    if old_name.has_notes? && (old_name.notes != notes)
      if has_notes?
        self.notes += "\n\nThese notes come from #{old_name.format_name} "\
                      "when it was merged with this name:\n\n #{old_name.notes}"
      else
        self.notes = old_name.notes
      end
      log(:log_name_updated, touch: true)
      save
    end

    # Finally destroy the name.
    old_name.destroy
  end

  ##############################################################################

  private

  def approved_synonym_of_proposed_name?
    !deprecated && Naming.where(name: other_synonyms).any?
  end

  def correctly_spelled_ancestor_of_proposed_name?
    return false if correct_spelling.present?
    return above_genus_is_ancestor? if classified_above_genus?
    return genus_or_species_is_ancestor? if [:Genus, :Species].include?(rank)
    return group_is_ancestor? if rank == :Group

    false
  end

  def above_genus_is_ancestor?
    Name.joins(:namings).where(
      "classification LIKE ?", "%#{rank}: _#{text_name}_%"
    ).any?
  end

  def genus_or_species_is_ancestor?
    Name.joins(:namings).where("text_name LIKE ?", "#{text_name} %").
      ranked_below(rank).any?
  end

  # Better than nothing for preventing accidental deletion of a Group.
  # although it catches only a few cases
  def group_is_ancestor?
    Name.joins(:namings).where(
      "text_name LIKE ?", "#{text_name.sub(/ (group|clade|complex)/, "")}%"
    ).where("`rank` != ?", Name.ranks[rank]).any?
  end
end
