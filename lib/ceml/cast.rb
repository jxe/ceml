module CEML
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

  RoleSpec = Struct.new :name, :tagspec, :range
  class Tagspec < Struct.new :with, :without
    def =~(c)
      with.all?{ |t| c[:tags].include?(t) } and without.all?{ |t| !c[:tags].include?(t) }
    end
  end
end
