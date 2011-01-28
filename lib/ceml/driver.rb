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

    LOCATIONS = Hash.new{ |h,k| h[k] = [] }
    def ping script, candidate
      return unless script.fits? candidate
      candidate[:ts] = CEML.clock
      script_id = script.text_value

      locs = LOCATIONS[script_id].group_by{ |l| l.stage_with_candidate(candidate) }
      if locs[:joinable]
        # puts "joining..."
        first = locs[:joinable].shift
        first.push candidate
        push first.incident_id, nil, candidate

      elsif locs[:launchable]
        # puts "launching..."
        first = locs[:launchable].shift
        first.push candidate
        cast = first.cast
        push nil, script, *cast
        (locs[:launchable] + (locs[:listable]||[])).each{ |l| l.rm *cast }

      elsif locs[:listable]
        # puts "listing..."
        locs[:listable].each{ |l| l.push candidate }

      else
        c = Confluence.new(script)
        case c.stage_with_candidate(candidate)
        when :launchable
          # puts "start-launching..."
          c.push candidate
          push nil, script, candidate
        when :listable
          # puts "start-listing..."
          c.push candidate
          LOCATIONS[script_id] << c
        else raise "what?"
        end

      end

      LOCATIONS[script_id].delete_if(&:full?)
      # save the changed ones and clear dirty flag
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
