module CEML

  class Criteria < Struct.new :plus_tags, :minus_tags, :matching, :radius, :timewindow
    def complexity; plus_tags.size; end
    def =~(candidate)
      candidate[:tags] ||= []
      (plus_tags - candidate[:tags]).empty? and (minus_tags & candidate[:tags]).empty?
    end
  end

  class Role < Struct.new :name, :criteria, :range, :casted
    # def <=>(b); b.criteria.complexity <=> criteria.complexity; end
    def affinity candidate, star
      return [-1, -1, -1 ] unless fits?(candidate, star)
      [ criteria.complexity, -needed, -allowed ]
    end

    def comparable_object
      [name, criteria, range]
    end

    def ==(other); comparable_object == other.comparable_object; end
    def hash; comparable_object.hash; end

    def filled?;   needed == 0; end
    def one_left?; needed == 1; end

    def rm(*ids); casted.delete_if{ |guy| ids.include? guy[:id] }; end
    def needed; [range.min - casted.size, 0].max; end
    def allowed; [range.max - casted.size, 0].max; end

    def over?(star)
      return unless criteria.timewindow and star
      CEML.clock - star[:ts] > criteria.timewindow
    end

    def fits?(candidate, star = nil)
      return false unless criteria =~ candidate
      return false if casted.size >= range.max
      return false if casted.any?{ |guy| guy[:id] == candidate[:id] }
      return true unless star
      c = criteria
      if c.matching
        return unless c.matching.all? do |g|
          candidate[:matchables][g] && star[:matchables][g] &&
          candidate[:matchables][g].downcase.strip == star[:matchables][g].downcase.strip
        end
      end
      if c.radius
        c_ll = Geokit::LatLng(candidate[:lat], candidate[:lng])
        s_ll = Geokit::LatLng(star[:lat], star[:lng])
        return unless c_ll.distance_to(s_ll, :meters) <= c.radius
      end
      if c.timewindow
        # puts "checking timewindow #{c.timewindow} #{candidate[:ts] - star[:ts]}"
        return unless candidate[:ts] - star[:ts] <= c.timewindow
      end
      return true
    end
  end
end
