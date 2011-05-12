module CEML

  class IncidentRoleSlot < Struct.new(:incident_id, :role, :max)
    def id; "#{incident_id}:#{role}"; end
    include Redis::Objects
    counter :casted

    def reserve_spot!
      casted.incr{ |val| val <= max }
    end
  end
end
