require 'redis/objects'

module Kernel
  def gen_code(size = 8)
    rand(36**size).to_s(36)
  end
end

module CEML
  class Processor

    # ===================
    # = scripts/bundles =
    # ===================

    def set_bundle(id, castables)
      # log "set_bundle(): #{id}, #{castables.inspect}"
      Bundle.new(id).castables = castables
    end

    def reset_bundle(id)
      Bundle.new(id).reset
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

    def ping(bundle_id, player)
      # log "ping(): #{bundle_id}, #{player[:id]}"
      Player.update(bundle_id, player, self) do |player|
        if incident_id = Player.new(player[:id]).top_incident_id
          IncidentModel.new(incident_id).run(self)
        else
          if player[:received]
            player_did_report({:player => player, :squad_id => bundle_id, :city => player[:city]}, nil)
          end
          simple_audition(bundle_id, player)
        end
      end
    end

    def reset_player(bundle_id, player_id)
      Player.new(player_id).reset
    end

    # =============
    # = internals =
    # =============

    def simple_audition(bundle_id, player)
      log "audition(): #{bundle_id}, #{player[:id]}"
      b = Bundle.new(bundle_id)
      b.clear_from_all_rooms(player)
      if incident_id = b.absorb?(player)
        IncidentModel.new(incident_id).run(self)
        return true
      end
      player_did_report({:player => player, :squad_id => bundle_id, :city => player[:city]}, nil)
      b.register_in_rooms(player)
    end

    def seed(bundle_id, stanza_name, player)
      log "seed(): #{bundle_id}, #{stanza_name}, #{player[:id]}"
      b = Bundle.new(bundle_id)
      if incident_id = b.absorb?(player, stanza_name)
        IncidentModel.new(incident_id).run(self)
        return true
      end
      b.register_in_rooms(player, stanza_name)
    end

    # =============
    # = callbacks =
    # =============

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
        player_obj.reset
        tell(player[:squad_id], player[:id], :message, :msg => 'aborted')
      else
        player_obj.reset
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
      JUST_SAID[player_id] ||= []
      JUST_SAID[player_id] << meta.merge(:key => key)
      # puts "Said #{key} #{meta.inspect}"
    end

    def player_answered_q(data, what)
      Player.update data[:id], data[:player].like(:id, :qs_answers), self
    end
    alias_method :player_set, :player_answered_q

    def player_seeded(data, what)
      p = data[:player].dup
      p.delete(:roles)
      p[:seeded] = "#{what[:target]}:#{what[:role]}"
      puts "SEEDED #{p[:id]} AS #{what[:target]}:#{what[:role]}"

      self.class.seed(p[:bundle_id], what[:target], p)
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
