module CEML
  class Bundle < Struct.new(:id)
    include Redis::Objects
    value :castables, :marshal => true

    def clear_from_all_rooms(player_id)
      Audition.new(player_id).clear_from_all_rooms
    end

    def find_castables(stanza_name = nil)
      return castables.value unless stanza_name
      return [castables.value.find{ |c| c.stanza_name == stanza_name }]
    end

    def all_rooms
      find_castables.map(&:all_rooms).flatten.uniq
    end

    def reset
      all_rooms.each(&:clear)
    end

    def rooms_for_player(player, stanza_name = nil)
      roomnames = find_castables(stanza_name).map{ |c| c.waiting_rooms_for_player(player, stanza_name) }.flatten.uniq
      roomnames.map{ |r| WaitingRoom.new(r) }
    end

    def join_running_incident?(player, stanza_name = nil)
      rooms_for_player(player, stanza_name).each do |room|
        if incident_id = room.audition_for_incidents(player)
          return incident_id
        end
      end
      false
    end

    def cast_player?(player, stanza_name = nil)
      incident_id  = gen_code
      find_castables(stanza_name).each do |castable|
        if cast = castable.cast_player?(incident_id, player, stanza_name)
          i = IncidentModel.new(incident_id)
          i.bytecode.value = castable.bytecode
          i.add_castings(cast.castings)
          return incident_id
        end
      end
      false
    end

    def absorb?(player, stanza_name = nil)
      x = join_running_incident?(player, stanza_name)
      puts "X1: #{x.inspect}"
      return x if x
      x = cast_player?(player, stanza_name)
      puts "X2: #{x.inspect}"
      x
    end

    def register_in_rooms(player, stanza_name = nil)
      Audition.new("#{player[:id]}").list_in_rooms(rooms_for_player(player, stanza_name))  ##{gen_code}:
    end

  end
end
