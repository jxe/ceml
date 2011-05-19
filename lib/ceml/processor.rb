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

    def set_bundle(id, castables)
      log "set_bundle(): #{id}, #{castables.inspect}"
      Bundle.new(id).castables = castables
    end

    # def updated(bundle_id, player)
    #   log "updated(): #{bundle_id}, #{player[:id]}"
    #   if incident_id = Player.new(player[:id]).active_incidents.last
    #     Player.update player
    #     run_incident(incident_id)
    #   else
    #     audition(bundle_id, player)
    #   end
    # end

    def audition_if_unengaged(bundle_id, player)
      log "audition_if_unengaged(): #{bundle_id}, #{player[:id]}"
      Player.update(player, self) do |player|
        if incident_id = Player.new(player[:id]).top_incident_id
          run_incident(incident_id)
        else
          _audition(bundle_id, player)
        end
      end
    end

    def replied(bundle_id, player)
      log "replied(): #{bundle_id}, #{player[:id]}"
      Player.update(player, self) do |player|
        if incident_id = Player.new(player[:id]).top_incident_id
          run_incident(incident_id)
        else
          player_did_report({:player => player, :squad_id => bundle_id, :city => player[:city]}, nil)
        end
      end
    end

    def audition(bundle_id, player)
      player.merge! :bundle_id => bundle_id
      Player.update(player, self) do |player|
        _audition(bundle_id, player)
      end
    end

    def recognize_override(cmd, new_message, player, player_obj)
      if respond_to?("override_#{cmd}")
        send("override_#{cmd}", new_message, player, player_obj)
        true
      end
    end

    def override_abort(new_message, player, player_obj)
      incident = player_obj.top_incident
      if incident
        incident.release(player_obj.id)
        unlatch(player[:squad_id], player[:id], incident.id)
        tell(player[:squad_id], player[:id], {:key => :message, :msg => 'aborted'})
      else
        tell(player[:squad_id], player[:id], {:key => :message, :msg => 'nothing to abort from'})
      end
    end

    def _audition(bundle_id, player)
      log "audition(): #{bundle_id}, #{player[:id]}"
      castables = Bundle.new(bundle_id).castables.value
      rooms = castables.map{ |c| c.waiting_rooms_for_player(player) }.flatten.uniq.map{ |r| WaitingRoom.new(r) }

      # check player against waiting incidents
      return true if rooms.detect{ |room| room.audition_for_incidents(player, self.class) }
      log "...cannot be cast into a live incident"

      # see if player makes a launch possible for any castable
      castables.each do |castable|
        room_ids = castable.hot_waiting_rooms_given_player(player)
        hotties = Audition.from_rooms(room_ids)
        log "hotties are... #{hotties.inspect} from rooms #{room_ids.inspect}"
        hot_players = hotties.keys.map{ |id| Player.new(id).data.value } + [player]

        log "casting from #{hot_players.inspect}"

        if cast = castable.cast_from(hot_players)
          log "...cast by #{castable.inspect} with cast #{cast.player_ids.inspect}"
          incident_id  = gen_code
          audition_ids = (cast.player_ids & hotties.keys).map{ |id| hotties[id] }

          log "consuming #{audition_ids.inspect}"
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
          return true
        end
      end

      # report here
      player_did_report({:player => player, :squad_id => bundle_id, :city => player[:city]}, nil)

      # bail out when there's no rooms relevant
      return false if rooms.empty?

      # store player in waiting rooms for later
      log "...storing in waiting rooms #{rooms}"
      Audition.new("#{player[:id]}").list_in_rooms(rooms)  ##{gen_code}:
      return true
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

    def player_said(data, what)
      tell('_', data[:player][:id], what)
    end

    def unlatch(sqid, player_id, incident_id)
      #no op
    end

    JUST_SAID = {}
    def tell(sqid, player_id, msg)
      JUST_SAID[player_id] = msg
      puts "Said #{msg.inspect}"
    end

    def player_answered_q(data, what)
      Player.update data[:player].like(:id, :qs_answers), self
    end
    alias_method :player_set, :player_answered_q

    def player_seed(data, what)
      p = data[:player].dup
      p.delete(:roles)
      p[:seeded] = "#{data[:target]}:#{data[:role]}"
      self.class.audition(p[:bundle_id], p)
    end

    def player_did_report(*args)
    end

    # these lines let this class act as a redis worker queing mechanism
    def self.method_missing(*args); Queue.new.calls << args; end
    def self.run(); Queue.new.run(self); end
  end
end
