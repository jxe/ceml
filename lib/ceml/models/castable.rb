module CEML
  class Castable < Struct.new :stanza_name, :matching, :radius, :timewindow, :roles, :bytecode

    def cast_player?(incident_id, player)
      room_ids = hot_waiting_rooms_given_player(player)
      hotties = Audition.from_rooms(room_ids)
      puts "hotties are... #{hotties.inspect} from rooms #{room_ids.inspect}"
      hot_players = hotties.keys.map{ |id| Player.new(id).data.value } + [player]
      puts "casting from #{hot_players.inspect}"
      if cast = cast_from(hot_players)
        puts "...cast with cast #{cast.player_ids.inspect}"
        audition_ids = (cast.player_ids & hotties.keys).map{ |id| hotties[id] }
        puts "consuming #{audition_ids.inspect}"
        if Audition.consume(audition_ids)
          yield :launch, cast

          # post audition signs in waiting rooms for remaining parts
          with_open_roles(cast) do |role, count|
            waiting_rooms_to_watch(role, cast).each do |room|
              room.list_job(incident_id, role.name, count)
            end
          end
        else
          yield :retry, nil
        end
      end
    end

    def waiting_rooms_for_player(player)
      result = []
      result.concat([*player[:seeded]]) if player[:seeded]
      result.concat player[:tags] if player[:tags]
      # result << 'generic'
      result
    end

    def hot_waiting_rooms_given_player(player)
      rooms = waiting_rooms_for_player(player)
      roles.each{ |r| rooms.concat(["#{stanza_name}:#{r.name}", *r.tagspec.with]) }
      rooms << "#{stanza_name}:*"
      # rooms << 'generic'
      rooms.uniq
    end

    def waiting_rooms_to_watch(role, cast)
      # skip for now: radius, timewindow, matching, general
      result = []
      if stanza_name
        result << "#{stanza_name}:#{role.name}"
        result << "#{stanza_name}:*"
      end
      if !role.tagspec.with.empty?
        result.concat role.tagspec.with
      end
      # result << 'generic'
      result.map{ |id| WaitingRoom.new(id) }
    end

    def with_open_roles(cast)
      roles.each do |role|
        count = cast.room(role)
        next unless count > 0
        yield role, count
      end
    end

    # an O(n*^2) alg for now.  can do much better
    def cast_from guys
      # see if we can build a cast out of them and bid on the casts
      possible_casts = guys.map{ |guy| Cast.new self, guy }.select(&:star)
      guys.each{ |guy| possible_casts.each{ |cast| cast.cast guy }}
      result = possible_casts.detect(&:complete?)
      result
    end
  end
end
