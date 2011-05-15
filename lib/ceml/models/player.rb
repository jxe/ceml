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

    def self.update player
      new(player[:id].to_s).update player
    end

    def clear_answers
      updating_lock.lock do
        value = data.value || {}
        value.delete(:qs_answers)
        value.delete(:received)
        data.value = value
      end
    end

    def update player
      puts "UPDATING player id #{id} with #{player.inspect}"
      new_message = player.like :received, :recognized, :situation
      if !new_message.empty?
        message.value = new_message
      end
      player.delete(:received)
      player.delete(:recognized)
      player.delete(:situation)
      updating_lock.lock do
        old_value = data.value || {}
        old_value.delete(:received)
        old_value.delete(:recognized)
        old_value.delete(:situation)
        new_value = old_value.merge player
        new_value[:qs_answers] = (old_value[:qs_answers]||{}).merge(player[:qs_answers] || {})
        puts "SAVING DATA: #{new_value.inspect}"
        data.value = new_value
      end
    end
  end
end
