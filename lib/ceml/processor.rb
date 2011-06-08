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
      castables.each{ |c| c.bundle_id = id }
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
      Bundle.new(bundle_id).reset_player(player_id)
    end

    # =============
    # = internals =
    # =============

    def simple_audition(bundle_id, player)
      # log "audition(): #{bundle_id}, #{player[:id]}"
      b = Bundle.new(bundle_id)
      b.clear_from_all_rooms(player[:id])

      if incident_id = b.absorb?(player)
        IncidentModel.new(incident_id).run(self)
        return true
      end
      player_did_report({:player => player, :squad_id => bundle_id, :city => player[:city]}, nil)
      b.register_in_rooms(player)
    end

    def seed(bundle_id, stanza_name, player)
      # log "seed(): #{bundle_id}, #{stanza_name}, #{player[:id]}"
      player[:tags].delete('new')
      Player.new(player[:id]).update(player)

      # CEML.log 1, "UPDATED"

      b = Bundle.new(bundle_id)
      if incident_id = b.absorb?(player, stanza_name)
        IncidentModel.new(incident_id).run(self)
        true
      else
        b.register_in_rooms(player, stanza_name)
        false
      end
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
        reset_player(player[:squad_id], player[:id])
        tell(player[:squad_id], player[:id], :message, :msg => 'aborted')
      else
        reset_player(player[:squad_id], player[:id])
        tell(player[:squad_id], player[:id], :message, :msg => 'nothing to abort from')
      end
    end

    def log(s)
      CEML.log 1, s
    end

    def player_said(data, what)
      tell('_', data[:player][:id], what[:key], what)
    end

    def unlatch(sqid, player_id, incident_id)
      #no op
    end

    def tell(sqid, player_id, key, meta)
      CEML.tells[player_id] << meta.merge(:key => key) if CEML.tells
    end

    def player_answered_q(data, what)
      Player.update data[:player][:bundle_id], data[:player].like(:id, :qs_answers), self
    end
    alias_method :player_set, :player_answered_q

    def player_seeded(data, what)
      p = data[:player].dup
      p.delete(:roles)
      p[:seeded] = "#{p[:bundle_id]}:#{what[:target]}:#{what[:role]}"
      CEML.log 3, "#{p[:id]}: seeded as #{p[:seeded]}"

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
