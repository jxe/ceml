require 'geokit'
require 'forwardable'

module CEML
  class Confluence
    attr_accessor :script, :hash, :created, :dirty, :roles_to_cast, :incident_id, :star
    alias_method :launched?, :incident_id

    def initialize script, candidate = nil
      @script  = script
      @hash    = {}
      @created = true
      @roles_to_cast = script.roles_to_cast
      push candidate if candidate
    end

    def rm *candidates
      @roles_to_cast.each{ |role| role.rm *candidates }
    end

    def best_role_for candidate
      winner = @roles_to_cast.max_by{ |role| role.affinity(candidate, star) }
      winner unless winner[0] == -1
    end

    def stage_with_candidate candidate
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
      @dirty = true
    end

    def full?
      @roles_to_cast.all?{ |role| role.allowed == 0 }
    end

    def cast
      @roles_to_cast.map{ |r| r.casted }.flatten
    end
  end
end
