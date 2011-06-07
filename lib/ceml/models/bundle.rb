module CEML
  class Bundle < Struct.new(:id)
    include Redis::Objects
    value :castables, :marshal => true

    # =============
    # = castables =
    # =============

    def find_castables(stanza_name = nil)
      return castables.value unless stanza_name
      return [castables.value.find{ |c| c.stanza_name == stanza_name }]
    end


    # =================
    # = waiting rooms =
    # =================

    def clear_from_all_rooms(player_id)
      CastingPool.destroy_everywhere(id, player_id)
    end

    def all_rooms
      find_castables.map(&:all_rooms).flatten.uniq
    end

    def reset
      # puts "TOTAL RESET"
      CastingTokens.destroy_all(id)
      all_rooms.each{ |room| room.waiting_incident_roles.clear }
    end

    def rooms_for_player(player, stanza_name = nil)
      find_castables(stanza_name).map{ |c| c.waiting_rooms_for_player(player, stanza_name) }.flatten.uniq
    end

    def register_in_rooms(player, stanza_name = nil)
      room_ids = rooms_for_player(player, stanza_name)
      CastingPool.new(room_ids).post(id, player[:id])
    end

    def reset_player(player_id)
      CastingPool.destroy_everywhere(id, player_id)
      Player.new(player_id).reset
    end

    def grab_cast?(player, castable, seeded_p)
      room_ids = castable.hot_waiting_rooms_given_player(player, seeded_p)
      # CEML.log 1, "Checking cast for #{castable.stanza_name}: #{room_ids.inspect}"
      casting_pool = CastingPool.new(room_ids)
      loop do
        hot_players = casting_pool.hot_players + [player]
        # CEML.log 1, "Hot players: #{hot_players.inspect}"
        return nil unless cast = castable.cast_from(hot_players)
        return cast if casting_pool.claim(cast.player_ids - [player[:id]])
        sleep 0.02
      end
    end

    # ==============================
    # = incident joining/launching =
    # ==============================

    def join_running_incident?(player, stanza_name = nil)
      rooms_for_player(player, stanza_name).each do |room_id|
        if incident_id = WaitingRoom.new(room_id).audition_for_incidents(player)
          return incident_id
        end
      end
      false
    end

    def cast_player?(player, stanza_name = nil)
      incident_id  = gen_code
      find_castables(stanza_name).each do |castable|
        if cast = grab_cast?(player, castable, seeded=stanza_name)
          castable.advertise_roles(incident_id, cast)
          i = IncidentModel.new(incident_id)
          i.bytecode.value = castable.bytecode
          i.add_castings(cast.castings)
          return incident_id
        end
      end
      false
    end

    def absorb?(player, stanza_name = nil)
      join_running_incident?(player, stanza_name) or cast_player?(player, stanza_name)
    end

  end
end
