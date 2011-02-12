require 'geokit'
require 'forwardable'

module CEML
  class Confluence
    attr_accessor :hash, :created, :roles_to_cast, :incident_id, :star
    alias_method :launched?, :incident_id

    def initialize roles_to_cast, candidate = nil
      @hash    = {}
      @created = true
      @roles_to_cast = roles_to_cast
      push candidate if candidate
    end

    def rm *candidates
      @roles_to_cast.each{ |role| role.rm *candidates }
    end

    def best_role_for candidate
      # puts "confluence finding best role #{object_id} #{candidate[:id]} #{star}"
      winner = @roles_to_cast.max_by{ |role| role.affinity(candidate, star) }
      winner unless winner.affinity(candidate, star)[0] == -1
    end

    def stage_with_candidate candidate
      return :uninterested if @roles_to_cast.any?{ |r| r.casted.any?{ |guy| guy[:id] == candidate[:id] } }
      best_role = best_role_for(candidate)
      return :uninterested unless best_role
      return :joinable if launched?
      other_roles = @roles_to_cast - [best_role]
      return :launchable if best_role.one_left? and other_roles.all?(&:filled?)
      return :listable
    end

    def push candidate
      best_role = best_role_for(candidate)
      candidate[:roles] = best_role.name.to_sym
      best_role.casted << candidate
      @star ||= candidate
    end

    def full?
      @roles_to_cast.all?{ |role| role.allowed == 0 }
    end

    def cast
      @roles_to_cast.map{ |r| r.casted }.flatten
    end
  end
end
