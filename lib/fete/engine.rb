require 'set'

module Fete
  class Engine
    attr_reader :script, :parts
    def this;       @parts[@current_id]; end
    def roles;      this[:roles] ||= Set.new; end
    def got;        this[:received];   end
    def recognized; this[:recognized]; end
    def pc;         this[:pc] ||= 0;   end

    def initialize(script_text, delegate = nil)
      @script = Fete.parse(:script, script_text)
      @delg   = delegate
      @parts  = {}
      @seq    = {}
    end

    def add(id, *roles)
      obj = Hash === roles[-1] ? roles.pop : {}
      parts[id] = obj.merge :roles => Set.new(roles)
    end

    def pass meth
      @delg.send(meth, self) if @delg and @delg.respond_to? meth
    end

    def run
      :continue while parts.keys.any?{ |@current_id| send(*seq[pc]) and pc+=1 }
    end

    # TODO
    def roles
      [script.roles.first, roles.include?(:organizer) && :organizer, :agents, :both, :all, :everyone]
    end

    def seq
      @seq[roles] ||= begin
        bytecode = [[:start]]
        instrs = script.instructions_for(roles)
        instrs.each do |inst|
          if inst.ask?
            bytecode << [:ask_q, inst]
            bytecode << [:answered_q, inst]
          elsif inst.tell? and script.title
            bytecode << [:assign, inst]
            bytecode << [:complete_assign, inst]
          elsif inst.tell? and not script.title
            bytecode << [:send_msg, inst]
          end
        end
        if instrs.empty? and script.title
          bytecode << [:null_assign]
          bytecode << [:complete_assign]
        end
        bytecode << [[:finish]]
      end
    end

    def say x, params = {}
      this[:said] = x
      this.merge! params
    end

    def qs_answers
      this[:qs_answers] ||= Hash.new
    end

    def expand(role, var)
      role = nil if role == 'otherguy'
      parts.each do |key, thing|
        next if key == @current_id
        next if role and not thing[:roles][role]
        value = qs_answers[var] and return value
      end
      nil
    end

    # ==============
    # = basic flow =
    # ==============

    def start
      roles[:agent] or return false
      pass :did_start
      true
    end

    def ask_q q
      text = q.interpolate(self) or return false
      say :ask, :q => text
      pass :did_ask
      true
    end

    def answered_q q
      got or return false
      qs_answers[q.key] = got
      pass :did_answer
      true
    end

    def send_msg a
      text = a.interpolate(self) or return false
      say :message, :msg => text
      pass :did_message
      true
    end

    def assign a
      text = a.interpolate(self) or return false
      say :assignment, :msg => text
      pass :did_assign
      true
    end

    def complete_assign a = nil
      got or return false
      if recognized == :done
        comment :ok
        true
      else
        pass :did_report
        false
      end
    end

    def null_assign
      comment :proceed
      true
    end

  end
end
