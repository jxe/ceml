module CEML

  class WaitingRoom < Struct.new(:id)
    include Redis::Objects
    set :waiting_auditions
    set :waiting_incident_roles

    def audition_for_incidents(player, klass)
      waiting_incident_roles.members.each do |key|
        incident_id, role, count = *key.split(':')
        count = count.to_i
        role_slot = IncidentRoleSlot.new(incident_id, role, count)
        next unless role_slot.reserve_spot!
        waiting_incident_roles.delete(key) if role_slot.full?
        klass.add_cast(role_slot.incident_id, { role_slot.role => [ player ] })
        return true
      end
      return false
    end

    def list_job(incident_id, rolename, count)
      waiting_incident_roles << [incident_id, rolename, count].join(':')
    end

    def add(audition_id)
      puts "adding #{audition_id} to waiting room #{id.inspect}"
      waiting_auditions << audition_id
    end
  end

end
