# encoding: utf-8

# Observation Change Email
class QueuedEmail::ObservationChange < QueuedEmail
  def observation; get_object(:observation, ::Observation, :allow_nil); end
  def note; get_note; end

  # This should be called when changes are made directly to observation.
  def self.change_observation(sender, recipient, observation)
    changes = []
    changes.push('date')                   if observation.when_changed?
    changes.push('location')               if observation.location_id_changed? || observation.where_changed?
    changes.push('notes')                  if observation.notes_changed?
    changes.push('specimen')               if observation.specimen_changed?
    changes.push('is_collection_location') if observation.is_collection_location_changed?
    changes.push('thumb_image_id')         if observation.thumb_image_id_changed?
    if email = find_email(recipient, observation)
      email.add_to_note_list(changes) if email.observation
    else
      email = create(sender, recipient)
      raise "Missing observation!" if !observation
      email.add_integer(:observation, observation.id)
      email.add_to_note_list(changes)
      email.finish
    end
    return email
  end

  # This should be called when an observation is destroyed.
  def self.destroy_observation(sender, recipient, observation)
    note = observation.unique_format_name
    if email = find_email(recipient, observation)
      email.add_integer(:observation, 0)
      email.set_note(note)
    else
      email = create(sender, recipient)
      email.add_integer(:observation, 0)
      email.set_note(note)
      email.finish
    end
    return email
  end

  # This should be called when images are added or removed from an observation.
  # The "action" parameter should be either :added_image or :removed_image.
  def self.change_images(sender, recipient, observation, action)
    if email = find_email(recipient, observation)
      email.add_to_note_list([action]) if email.observation
    else
      email = create(sender, recipient)
      raise "Missing observation!" if !observation
      email.add_integer(:observation, observation.id)
      email.add_to_note_list([action])
      email.finish
    end
    return email
  end

  def deliver_email
    ObservationChangeEmail.build(user, to_user, observation, note, queued).deliver
  end

################################################################################

private

  # Check to see if there is already an email started.
  def self.find_email(recipient, observation)
#    QueuedEmail.first(:include => :queued_email_integers, # Rails 3
#      :conditions => [
#        'queued_emails.to_user_id = ?' +
#        ' and queued_emails.flavor = "QueuedEmail::ObservationChange"' +
#        ' and queued_email_integers.key = "observation"' +
#        ' and queued_email_integers.value = ?', recipient.id, observation.id])
    QueuedEmail.
      where("queued_emails.flavor = 'QueuedEmail::ObservationChange' AND
             queued_email_integers.key = 'observation' AND
             queued_email_integers.value = ? AND queued_emails.to_user_id = ?",
             observation.id, recipient.id).
      first.
      include(:queued_email_integers)
  end
end
