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
      INCIDENTS[id] ||= CEML::Incident.new script, id if script
      raise "no incident #{id}" unless INCIDENTS[id]
      yield INCIDENTS[id], PLAYERS[id], metadata if block_given?
      id
    end
    alias_method :start, :with_incident

    LOCATIONS = {}
    def ping script, candidate, metadata = {}
      LOCATIONS[script] ||= []
      script.post candidate, LOCATIONS[script]
      LOCATIONS[script].delete_if do |loc|
        next unless loc.cast
        with_incident nil, script, metadata do |incident, players, metadata|
          loc.cast.each{ |guy| subpost incident, players, metadata, guy.initial_state }
        end
      end
    end

    def post incident_id, player = nil
      with_incident incident_id do |incident, players, metadata|
        subpost incident, players, metadata, player
      end
    end
    alias_method :run, :post

    def subpost incident, players, metadata, player = nil
      if player
        player_id = player[:id]
        player[:roles] = Set.new([*player[:roles] || []])
        player[:roles] << :agents
        if existing_player = players.find{ |p| p[:id] == player_id }
          existing_player[:roles] += player.delete :roles
          existing_player.update player
        else
          players << player
        end
      end
      incident.run(players) do |player, meth, what|
        meth = "player_#{meth}"
        send(meth, incident.id, metadata, player, what) if respond_to? meth
      end
    end

    JUST_SAID = {}
    def player_said(incident_id, metadata, player, what)
      JUST_SAID[player[:id]] = what
      puts "Said #{what.inspect}"
    end
  end
end
