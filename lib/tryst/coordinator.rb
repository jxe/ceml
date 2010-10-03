require 'set'

module Tryst
  class Coordinator < Struct.new(:elements)
    def self.tasks(what=nil); what ? @tasks = what : @tasks; end
    def this; elements[@current_id]; end
    def states; this[:states] ||= Set.new; end
    def did(*syms);   syms.all?{ |sym|  states.include? sym }; end
    def didnt(*syms); syms.all?{ |sym| !states.include? sym }; end

    def run
      progress = false
      self.class.tasks.each_pair do |condition, methods|
        elements.keys.each do |@current_id|
          next unless did condition and didnt :retire
          remaining = methods.select{ |m| didnt m }
          progressed = remaining.select{ |m| did(m) || send(m) and progress=true }
          states.merge progressed
          states << :retire if (remaining - progressed).empty?
        end
      end
      run if progress
    end
  end
end
