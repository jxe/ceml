module CEML
  class Player < Struct.new(:id)
    include Redis::Objects
    lock :updating
    value :data,    :marshal => true
    value :message, :marshal => true
    sorted_set :current_incidents

    def touch(incident_id)
      current_incidents[incident_id] = Time.now.to_i
    end

    def reset
      Audition.new(id).clear_from_all_rooms
      data.clear
      message.clear
      current_incidents.clear
    end

    def top_incident_id
      current_incidents.last
    end

    def top_incident
      if iid = top_incident_id
        IncidentModel.new(iid)
      end
    end

    def clear_incident(id)
      current_incidents.delete(id)
    end

    def self.update bundle_id, player, cb_obj, &blk
      player[:bundle_id] = player[:squad_id] = bundle_id
      new(player[:id].to_s).update player, cb_obj, &blk
    end

    def clear_answers
      updating_lock.lock do
        value = data.value || {}
        value.delete(:qs_answers)
        value.delete(:received)
        data.value = value
      end
    end

    MSG_PARAMS = [:received, :recognized, :situation]

    def split player
      new_message = player.like(*MSG_PARAMS)
      MSG_PARAMS.each{ |p| player.delete(p) }
      return new_message, player
    end

    def merge_new_player_data player
      updating_lock.lock do
        old_value = data.value || {}
        new_value = old_value.merge player
        new_value[:qs_answers] = (old_value[:qs_answers]||{}).merge(player[:qs_answers] || {})
        # puts "SAVING DATA: #{new_value.inspect}"
        data.value = new_value
      end
    end

    def update player, cb_obj
      player = player.dup
      # puts "UPDATING player id #{id} with #{player.inspect}"
      new_message, player = split(player)
      merge_new_player_data(player)
      cmd = new_message[:recognized]
      if cmd and cb_obj.recognize_override(cmd, new_message, player, self)
        message.delete
      else
        message.value = new_message
        yield player if block_given?
      end
    end
  end
end
