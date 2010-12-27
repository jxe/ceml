require 'geokit'
require "forwardable"

module CEML
  class Candidate < Struct.new :uid, :tags, :matchables, :lat, :lng
    include Geokit::Mappable
  end

  class CastingCriterion < Struct.new :script, :plus_tags, :minus_tags, :grouped_by, :radius, :role_counts
    extend Forwardable
    def_delegators :script, :locations
    def min_match;  role_counts.values.reduce(:+); end
    def complexity; plus_tags.size; end

    def =~(candidate)
      (plus_tags - candidate.tags).empty? and (minus_tags & candidate.tags).empty?
    end

    def satisfied_by_group?(people, already_used)
      if (people - already_used).size >= min_match
        already_used.concat((people - already_used).first(min_match))
        true
      end
    end

    def list_candidate(candidate)
      locs = locations.select do |l|
        star = l.values.flatten.first
        next unless grouped_by.all?{ |g| candidate.matchables[g] == star.matchables[g] }
        !radius or candidate.distance_to(star, :meters) <= radius
      end
      if locs.empty?
        new_loc = {}
        [locations, locs].each{ |l| l << new_loc }
      end
      locs.each{ |l| (l[hash] ||= []) << candidate }
    end
  end
end
