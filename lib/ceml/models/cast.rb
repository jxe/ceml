module CEML

  RoleSpec = Struct.new :name, :tagspec, :range

  class Castable < Struct.new :stanza_name, :matching, :radius, :timewindow, :roles, :bytecode

    def waiting_rooms_for_player(player)
      result = []
      result.concat player[:seeded] if player[:seeded]
      result.concat player[:tags] if player[:tags]
      result << 'generic'
      result
    end

    def hot_waiting_rooms_given_player(player)
      rooms = waiting_rooms_for_player(player)
      roles.each{ |r| rooms.concat(["#{stanza_name}:#{r.name}", *r.tagspec.with]) }
      rooms << "#{stanza_name}:*"
      rooms << 'generic'
      rooms
    end

    def waiting_rooms_to_watch(role, cast)
      # skip for now: radius, timewindow, matching, general
      result = []
      if stanza_name
        result << "#{stanza_name}:#{role.name}"
        result << "#{stanza_name}:*"
      end
      if !role.tagspec.with.empty?
        result.concat role.tagspec.with
      end
      result << 'generic'
      result.map{ |id| WaitingRoom.new(id) }
    end

    def with_open_roles(cast)
      roles.each do |role|
        count = cast.room(role)
        next unless count > 0
        yield role, count
      end
    end

    # an O(n*^2) alg for now.  can do much better
    def cast_from guys
      # see if we can build a cast out of them and bid on the casts
      possible_casts = guys.map{ |guy| Cast.new self, guy }.select(&:star)
      guys.each{ |guy| possible_casts.each{ |cast| cast.cast guy }}
      result = possible_casts.detect(&:complete?)
      result
    end
  end

  # this contains the logic of building and approving a valid cast
  # for an await statement, starting with a seed first_guy
  class Cast
    extend Forwardable
    attr_reader :castings
    def_delegators :@castable, :timewindow, :radius, :matching, :roles
    def_delegators :@castings, :[]
    def initialize(castable, first_guy)
      @castable = castable
      @castings = Hash.new{ |h,k| h[k] = Set.new }
      cast first_guy
    end

    def room(role)
      casted_count = @castings[role.name].size
      [role.range.max - casted_count, 0].max
    end

    def affinity role, guy
      casted_count = @castings[role.name].size
      needed =  [role.range.min - casted_count, 0].max
      allowed = [role.range.max - casted_count, 0].max

      return [-1, -1, -1 ] unless role.tagspec =~ guy and allowed > 0
      [ role.tagspec.with.size, -needed, -allowed ]
    end

    def <=>(other)
      castings <=> other.castings
    end

    def cast guy
      return if included? guy or not self =~ guy
      best_role = roles.max_by{ |role| affinity(role, guy) }
      return if affinity(best_role, guy)[0] == -1
      @castings[best_role.name] << guy
      guy[:roles] = best_role.name.to_sym
    end

    def included? guy
      folks.any?{ |fellow| fellow[:id] == guy[:id] }
    end

    def complete?
      roles.all?{ |role| castings[role.name].size >= role.range.min }
    end

    def folks
      castings.values.map(&:to_a).flatten
    end

    def player_ids
      folks.map{ |p| p[:id] }
    end

    def star
      folks.first
    end

    def closes_at
      return nil unless star && timewindow
      star[:ts] + timewindow
    end

    def matchings
      return {} unless star
      Hash[ *matching.map{ |k| [k, star[:matchables][k]] } ]
    end

    def circle
      return nil unless star && radius
      llr = star[:lat] && star[:lng] && [star[:lat], star[:lng], radius]
      ll && Circle.new(*llr)
    end

    def tagspecs
      roles.map(&:tagspec).uniq
    end

    def =~(c)
      (!closes_at or closes_at < Time.unix) and
      (!circle or circle.contains?(c[:lat], c[:lng])) and
      (matchings.each{ |k,v| c[:matchables][k] == v }) and
      (tagspecs.any?{ |ts| ts =~ c })
    end
  end

  class Circle < Struct.new :lat, :lng, :radius
    def center; Geokit::LatLng(lat, lng); end
    def contains?(*ll)
      center.distance_to(Geokit::LatLng(*ll), :meters) <= radius
    end
  end

  class Tagspec < Struct.new :with, :without
    def =~(c)
      with.all?{ |t| (c[:tags]||[]).include?(t) } and without.all?{ |t| !(c[:tags]||[]).include?(t) }
    end
  end
end
