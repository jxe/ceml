module CEML
  class Castable < Struct.new :type, :stanza_name, :matching, :radius, :timewindow, :roles, :bytecode, :bundle_id

    def advertise_roles(incident_id, cast)
      with_open_roles(cast) do |idx, role, count|
        waiting_rooms_to_watch(role, cast).each do |room|
          room.list_job(incident_id, idx, role.name, count)
        end
      end
    end

    def waiting_rooms_for_player(player, seeded=false)
      result = []
      result.concat([*player[:seeded]]) if player[:seeded]
      result.concat player[:tags] if player[:tags] unless seeded
      # result << 'generic'
      result
    end

    def hot_waiting_rooms_given_player(player, seeded=false)
      rooms = waiting_rooms_for_player(player, seeded)
      roles.each{ |r| rooms.concat(["#{bundle_id}:#{stanza_name}:#{r.name}", *r.tagspec.with]) }
      rooms << "#{bundle_id}:#{stanza_name}:*"
      # rooms << 'generic'
      rooms.uniq
    end

    def waiting_rooms_to_watch(role, cast)
      # skip for now: radius, timewindow, matching, general
      result = []
      if stanza_name
        result << "#{bundle_id}:#{stanza_name}:#{role.name}"
        result << "#{bundle_id}:#{stanza_name}:*"
      end
      if !role.tagspec.with.empty?
        result.concat role.tagspec.with
      end
      # result << 'generic'
      result.map{ |id| WaitingRoom.new(id) }
    end

    def all_rooms
      roles.map{ |r| waiting_rooms_to_watch(r, {}) }.flatten
    end

    def with_open_roles(cast)
      roles.each_with_index do |role, i|
        count = cast.room(role)
        next unless count > 0
        yield i, role, count
      end
    end

    # an O(n*^2) alg for now.  can do much better
    def cast_from guys
      # see if we can build a cast out of them and bid on the casts
      possible_casts = guys.map{ |guy| Cast.new self, guy }.select(&:star)
      guys.each{ |guy| possible_casts.each{ |cast| cast.cast guy }}
      result = possible_casts.detect(&:launchable?)
      result
    end
  end
end
