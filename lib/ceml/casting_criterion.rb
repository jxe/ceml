require 'geokit'
require "forwardable"

module CEML
  class Candidate < Struct.new :uid, :tags, :matchables, :lat, :lng, :initial_state
    include Geokit::Mappable
    attr_reader :criteria

    def load(criteria)
      @criteria = criteria.select{ |c| c =~ self }
      if @criteria.empty? then nil else self end
    end

    def criteria_for_location(star)
      criteria.select{ |c| c.fits?(self, star) }
    end
  end

  class CastingLocation < Struct.new :script, :hash, :created
    attr_accessor :added
    def star; hash.values.flatten.first; end

    def criteria
      @criteria ||= script.awaited_criteria.sort_by{ |c| [-c.complexity, c.min_match] }
    end

    def push candidate
      matching_criteria = candidate.criteria_for_location(star)
      return if matching_criteria.empty?
      matching_criteria.each{ |c| (hash[c] ||= []) << candidate }
      @added = true
    end

    def self.create script, candidate
      new(script, {}, true).tap{ |x| x.push candidate }
    end

    # this method will miss possible castings and does not handle ranges at all
    def cast
      [].tap do |casting|
        criteria.each do |c|
          return nil unless folks = hash[c].dup
          folks -= casting
          return nil unless folks.size >= c.min_match
          c.role_counts.each do |role, minct|
            folks.shift(minct).each do |guy|
              guy.initial_state ||= {}
              guy.initial_state[:id] = guy.uid
              guy.initial_state[:roles] = role.to_sym
              casting << guy
            end
          end
        end
      end
    end
  end

  class CastingCriterion < Struct.new :script, :plus_tags, :minus_tags, :grouped_by, :radius, :role_counts
    def min_match;  role_counts.values.reduce(:+); end
    def complexity; plus_tags.size; end

    def =~(candidate)
      (plus_tags - candidate.tags).empty? and (minus_tags & candidate.tags).empty?
    end

    def fits?(candidate, star)
      return true unless star
      return unless grouped_by.all?{ |g| candidate.matchables[g] == star.matchables[g] }
      p radius
      !radius or candidate.distance_to(star, :meters) <= radius
    end
  end
end

# def satisfied_by_group?(people, already_used)
#   if (people - already_used).size >= min_match
#     already_used.concat((people - already_used).first(min_match))
#     true
#   end
# end

# this method and the one below will miss possible
# castings and do not handle ranges at all
# def complete?(loc)
#   people_used = []
#   @criteria.all? do |c|
#     next unless folks = loc[c.hash]
#     c.satisfied_by_group?(folks, people_used)
#   end
# end
