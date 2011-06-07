module CEML

  class WaitingRoom < Struct.new(:id)
    include Redis::Objects
    set :waiting_auditions
    set :waiting_incident_roles

    def audition_for_incidents(player)
      reorder = waiting_incident_roles.members.sort_by{ |irs| irs.split(':')[1] }
      reorder.each do |key|
        incident_id, idx, role, count = *key.split(':')
        CEML.log 3, "#{player[:id]}: auditioning against #{incident_id}: #{role}"
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
  end

end
