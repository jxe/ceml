require 'set'

module Kernel
  def gen_code(size = 8)
    rand(36**size).to_s(36)
  end
end

module CEML
  class Driver

    PLAYERS   = {}
    INCIDENTS = {}
    def with_incident(id, script = nil, metadata = {})
      id ||= rand(36**10).to_s(36)
      PLAYERS[id] ||= []
      INCIDENTS[id] ||= CEML::Incident.new to_bytecode(script), id if script
      raise "no incident #{id}" unless INCIDENTS[id]
      yield INCIDENTS[id], PLAYERS[id], metadata if block_given?

      PLAYERS[id].select{ |p| p[:released] }.each do |p|
        release p
        ping_all p[:script_collection_id], p
      end

      id
    end
    alias_method :start, :with_incident

    def to_bytecode bytecode_or_script
      case bytecode_or_script
      when String;       return CEML.parse(:script, bytecode_or_script).bytecode
      when CEML::Script; return bytecode_or_script.bytecode
      when Array;        return bytecode_or_script
      else return nil
      end
    end

    def log(s)
      # puts s
    end

    SCRIPTS = Hash.new{ |h,k| h[k] = [] }
    def add_script script_collection_id, script
      SCRIPTS[script_collection_id] << script
    end

    def release p
      p[:tags] -= ['new']
      if p[:released] =~ /^(\w+)=/
        p[:tags].delete_if{ |t| t =~ /^#{$1}=/ }
      end
      p[:tags] += [p[:released]]
      [:pc, :roles, :released].each{ |sym| p.delete(sym) }
      (p[:matchables]||={}).update (p[:qs_answers]||{})
    end

    def launch id, script_collection_id, roleset, *cast
      script = SCRIPTS[script_collection_id].select{ |s| s.roles_to_cast == roleset }.sort_by{ rand }.first
      unless script
        rolesets = SCRIPTS[script_collection_id].map(&:roles_to_cast)
        raise "matching roleset not found: #{roleset.inspect} in #{rolesets.inspect}"
      end
      log "launching #{script.bytecode.inspect} with cast #{cast.inspect}"
      push id, script.bytecode, *cast
    end


    LOCATIONS = Hash.new{ |h,k| h[k] = [] }
    def with_confluences script_collection_id, roleset
      yield LOCATIONS["#{script_collection_id}:#{roleset.hash}"]
    end

    def push incident_id, script, *updated_players
      with_incident incident_id, script do |incident, players, metadata|
        subpost incident, players, metadata, *updated_players
      end
    end

    def post incident_id, *updated_players
      push incident_id, nil, *updated_players
    end

    alias_method :run, :post

    def subpost incident, players, metadata, *updated_players
      updated_players.each do |player|
        player_id = player[:id]
        player[:roles] = Set.new([*player[:roles] || []])
        player[:roles] << :agents << :players << :both << :all << :each << :everyone
        if existing_player = players.find{ |p| p[:id] == player_id }
          existing_player[:roles] += player.delete :roles
          existing_player.update player
        else
          players << player
        end
      end
      incident.run(players) do |player, meth, what|
        meth = "player_#{meth}"
        log "[#{incident.id}] #{meth}: #{player[:id]} #{what.inspect}"
        if respond_to? meth
          metadata.update :player => player, :players => players, :id => incident.id
          result = send(meth, metadata, what)
          metadata.delete :player
          metadata.delete :players
          result
        end
      end
    end

    JUST_SAID = {}
    def player_said(data, what)
      JUST_SAID[data[:player][:id]] = what
      puts "Said #{what.inspect}"
    end

    # def player_start(data, what)
    #   puts "STARTED #{data[:player].inspect}"
    # end
  end
end
