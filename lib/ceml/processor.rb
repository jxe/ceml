require 'redis/objects'

module Kernel
  def gen_code(size = 8)
    rand(36**size).to_s(36)
  end
end

module CEML
  class Processor
    def ctx(options = {}); Context.new(self, options); end

    # ===================
    # = scripts/bundles =
    # ===================

    def set_bundle(id, castables)
      log "set_bundle(): #{id}, #{castables.inspect}"
      Bundle.new(id).castables = castables
    end

    def run_latest
      IncidentModel.run_latest(self)
    end


    # =============
    # = incidents =
    # =============

    def launch(incident_id, bytecode)
      incident_id ||= gen_code
      IncidentModel.new(incident_id).bytecode.value = bytecode
    end

    def add_cast(incident_id, castings)
      i = IncidentModel.new(incident_id)
      i.add_castings(castings)
      i.run(self)
    end


    # ============
    # = requests =
    # ============

    def audition_if_unengaged(bundle_id, player)
      log "audition_if_unengaged(): #{bundle_id}, #{player[:id]}"
      Player.update(bundle_id, player, self) do |player|
        if incident_id = Player.new(player[:id]).top_incident_id
          run_incident(incident_id)
        else
          _audition(bundle_id, player)
        end
      end
    end

    def replied(bundle_id, player)
      log "replied(): #{bundle_id}, #{player[:id]}"
      Player.update(bundle_id, player, self) do |player|
        if incident_id = Player.new(player[:id]).top_incident_id
          run_incident(incident_id)
        else
          player_did_report({:player => player, :squad_id => bundle_id, :city => player[:city]}, nil)
        end
      end
    end


    # =============
    # = internals =
    # =============

    def run_incident(id)
      IncidentModel.new(id).run(self)
    end

    # currently used by seed
    def audition(bundle_id, player)
      player.merge! :bundle_id => bundle_id
      Player.update(bundle_id, player, self) do |player|
        _audition(bundle_id, player)
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
      incident_id  = gen_code
      castables.each do |castable|
        castable.cast_player?(incident_id, player) do |result, cast|
          case result
          when :launch
            launch(incident_id, castable.bytecode)
            add_cast(incident_id, cast.castings)
            return true
          when :retry
            sleep 0.02
            return audition(scripts, player)
          end
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


    # =============
    # = callbacks =
    # =============

    # def log ctx, attempt, status, pc, instr, args
    #   # ctx: bundle_id, persona_id, persona_name, incident_id
    #   # args: attempt, status
    #   # incident_decore: pc, instr, args
    #
    # end

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
        tell(player[:squad_id], player[:id], :message, :msg => 'aborted')
      else
        tell(player[:squad_id], player[:id], :message, :msg => 'nothing to abort from')
      end
    end

    def log(s)
      puts s
    end

    def player_said(data, what)
      tell('_', data[:player][:id], what[:key], what)
    end

    def unlatch(sqid, player_id, incident_id)
      #no op
    end

    JUST_SAID = {}
    def tell(sqid, player_id, key, meta)
      JUST_SAID[player_id] = meta.merge :key => key
      puts "Said #{key} #{meta.inspect}"
    end

    def player_answered_q(data, what)
      Player.update data[:id], data[:player].like(:id, :qs_answers), self
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


    # ====================
    # = queue processing =
    # ====================

    def self.method_missing(*args); Queue.new.calls << args; end
    def self.run(); Queue.new.run(self); end
  end
end
