module CEML

  class WaitingRoom < Struct.new(:id)
    include Redis::Objects
    set :waiting_auditions
    set :waiting_incident_roles

    def clear
      waiting_auditions.each do |audition_id|
        Audition.new(audition_id).clear_from_all_rooms(id)
      end
      waiting_incident_roles.clear
    end

    def audition_for_incidents(player)
      # puts "auditioning #{player[:id]} for incidents in room #{id}"
      waiting_incident_roles.members.each do |key|
        incident_id, idx, role, count = *key.split(':')
        # puts "checking against #{incident_id}: #{role}"
        count = count.to_i
        role_slot = IncidentRoleSlot.new(incident_id, role, count)
        next unless role_slot.reserve_spot!
        waiting_incident_roles.delete(key) if role_slot.full?
        IncidentModel.new(role_slot.incident_id).add_castings({ role_slot.role => [ player ] })
        return role_slot.incident_id
      end
      return false
    end

    def list_job(incident_id, idx, rolename, count)
      waiting_incident_roles << [incident_id, idx, rolename, count].join(':')
    end

    def add(audition_id)
      puts "adding #{audition_id} to waiting room #{id.inspect}"
      waiting_auditions << audition_id
    end
  end

end
