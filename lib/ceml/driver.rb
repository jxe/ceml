require 'set'

module Kernel
  def gen_code(size = 8)
    rand(36**size).to_s(36)
  end
end

module CEML
  class Driver
    LOCATIONS = {}
    PLAYERS   = {}
    INCIDENTS = {}
    JUST_SAID = {}

    def start(script, id = rand(36**10).to_s(36))
      x = CEML::Incident.new script, id
      INCIDENTS[id] = x
      PLAYERS[id] = []
      id
    end

    def player_said(incident_id, player, what)
      JUST_SAID[player[:id]] = what
      puts "Said #{what.inspect}"
    end

    def run(incident_id)
      INCIDENTS[incident_id].run(PLAYERS[incident_id]) do |player, meth, what|
        meth = "player_#{meth}"
        send(meth, incident_id, player, what) if respond_to? meth
      end
    end

    def post incident_id, player
      player_id = player[:id]
      player[:roles] = Set.new([*player[:roles] || []])
      player[:roles] << :agents
      if existing_player = PLAYERS[incident_id].find{ |p| p[:id] == player_id }
        existing_player[:roles] += player.delete :roles
        existing_player.update player
      else
        PLAYERS[incident_id] << player
      end
      run incident_id
    end

    def ping script, candidate
      LOCATIONS[script] ||= []
      script.post candidate, LOCATIONS[script]
      LOCATIONS[script].delete_if do |loc|
        next unless loc.cast
        iid = start(script)
        loc.cast.each{ |guy| post iid, guy.initial_state }
      end
    end
  end
end
