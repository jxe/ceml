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
    def with_incident(id, script = nil)
      id ||= rand(36**10).to_s(36)
      PLAYERS[id] ||= []
      INCIDENTS[id] ||= CEML::Incident.new script, id if script
      raise "no incident #{id}" unless INCIDENTS[id]
      yield INCIDENTS[id], PLAYERS[id] if block_given?
      id
    end

    LOCATIONS = {}
    def ping script, candidate
      LOCATIONS[script] ||= []
      script.post candidate, LOCATIONS[script]
      LOCATIONS[script].delete_if do |loc|
        next unless loc.cast
        with_incident nil, script do |incident, players|
          loc.cast.each{ |guy| subpost incident, players, guy.initial_state }
        end
      end
    end

    def start(script, id = nil)
      with_incident(id, script)
    end

    def post incident_id, player
      with_incident incident_id do |incident, players|
        subpost incident, players, player
      end
    end

    def subpost incident, players, player
      player_id = player[:id]
      player[:roles] = Set.new([*player[:roles] || []])
      player[:roles] << :agents
      if existing_player = players.find{ |p| p[:id] == player_id }
        existing_player[:roles] += player.delete :roles
        existing_player.update player
      else
        players << player
      end
      run incident, players
    end

    JUST_SAID = {}
    def player_said(incident_id, player, what)
      JUST_SAID[player[:id]] = what
      puts "Said #{what.inspect}"
    end

    def run(incident, players)
      incident.run(players) do |player, meth, what|
        meth = "player_#{meth}"
        send(meth, incident.id, player, what) if respond_to? meth
      end
    end
  end
end
