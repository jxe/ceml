require 'redis/objects'

module Kernel
  def gen_code(size = 8)
    rand(36**size).to_s(36)
  end
end

module CEML
  class Processor
    # TODO:  new way to release players from incident
    # design:  release, replace, incident_close

    def updated(castables, player)
      if incident_id = Player.new(player[:id]).active_incidents.last
        Player.update player
        run_incident(incident_id)
      else
        audition(castables, player)
      end
    end

    def audition(castables, player)
      Player.update player
      log "Auditioning #{player[:id]}"
      rooms = castables.map{ |c| c.waiting_rooms_for_player(player) }.flatten.uniq.map{ |r| WaitingRoom.new(r) }

      # check player against waiting incidents
      return if rooms.detect{ |room| room.audition_for_incidents(player) }
      log "...cannot be cast into a live incident"

      # see if player makes a launch possible for any castable
      castables.each do |castable|
        room_ids = castable.hot_waiting_rooms_given_player(player)
        hotties = Audition.from_rooms(room_ids)
        log "hotties are... #{hotties.inspect} from rooms #{room_ids.inspect}"
        hot_players = hotties.keys.map{ |id| Player.new(id).data.value } + [player]

        log "casting from #{hot_players.inspect}"

        if cast = castable.cast_from(hot_players)
          log "...cast by #{castable.inspect}"
          incident_id  = gen_code
          audition_ids = cast.player_ids.map{ |id| hotties[id] }

          Audition.consume(audition_ids) do
            launch(incident_id, castable.bytecode)
            # post audition signs in waiting rooms for remaining parts
            castable.with_open_roles(cast) do |role, count|
              castable.waiting_rooms_to_watch(role, cast).each do |room|
                room.list_job(incident_id, role.name, count)
              end
            end
          end or begin sleep 0.02; return audition(scripts, player); end

          add_cast(incident_id, cast.castings)
          return
        end
      end

      # store player in waiting rooms for later
      log "...storing in waiting rooms #{rooms}"
      Audition.new("#{gen_code}:#{player[:id]}").list_in_rooms(rooms)
    end

    def launch(incident_id, bytecode)
      incident_id ||= gen_code
      IncidentModel.new(incident_id).bytecode.value = bytecode
    end

    def run_latest
      IncidentModel.run_latest(self)
    end

    def add_cast(incident_id, castings)
      puts "adding cast!"
      i = IncidentModel.new(incident_id)
      i.add_castings(castings)
      i.run(self)
    end

    def run_incident(id)
      IncidentModel.new(id).run(self)
    end

    def log(s)
      puts s
    end

    JUST_SAID = {}
    def player_said(data, what)
      JUST_SAID[data[:player][:id]] = what
      puts "Said #{what.inspect}"
    end

    def player_answered_q(data, what)
      Player.update data[:player].like(:id, :qs_answers)
    end
    alias_method :player_set, :player_answered_q

    # these lines let this class act as a redis worker queing mechanism
    def self.method_missing(*args); Queue.new.calls << args; end
    def self.run(); Queue.new.run; end
  end
end