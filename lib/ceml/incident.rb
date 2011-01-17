require 'set'

module CEML
  class Incident
    attr_reader :script, :id, :this
    def roles;      this[:roles] ||= Set.new; end
    def got;        this[:received];   end
    def recognized; this[:recognized]; end
    def pc;         this[:pc] ||= 0;   end
    def qs_answers; this[:qs_answers] ||= Hash.new; end

    def handled!
      this.delete :received
      this.delete :recognized
    end

    def initialize(script, id)
      @id = id
      @script = Script === script ? script : CEML.parse(:script, script)
    end

    def cb *stuff
      @callback.call this, *stuff if @callback
    end

    def run(players, &blk)
      @players = players
      @callback = blk
      :loop while players.any? do |@this|
        # puts "seq for roles: #{roles.inspect} #{seq.inspect}"
        next unless seq[pc] and send(*seq[pc])
        cb(*seq[pc])
        this[:pc]+=1
      end
      @callback = @players = nil
    end

    def seq
      @seq ||= {}
      @seq[roles] ||= begin
        bytecode = [[:start]]
        instrs = script.instructions_for(roles)
        instrs.each do |inst|
          case inst.cmd
          when :register
            bytecode << [:answered_q, inst]
          when :ask
            bytecode << [:ask_q, inst]
            bytecode << [:answered_q, inst]
          when :tell
            if script.title
              bytecode << [:assign, inst]
              bytecode << [:complete_assign, inst]
            else
              bytecode << [:send_msg, inst]
            end
          end
        end
        if instrs.empty? and script.title
          bytecode << [:null_assign]
          bytecode << [:complete_assign]
        end
        bytecode << [:finish]
      end
    end

    def expand(role, var)
      return (this[:qs_answers]||{})[var] if role =~ /^his|her$/
      role = nil if role == 'otherguy'
      role = role.to_sym if role
      @players.each do |p|
        next if p == this
        next if role and not p[:roles].include? role
        value = (p[:qs_answers]||{})[var] and return value
      end
      nil
    end

    # ==============
    # = basic flow =
    # ==============

    def say x, params = {}
      cb :said, params.merge(:said => x)
    end

    def start
      # roles.include? :agent or return false
      true
    end

    def ask_q q
      text = q.interpolate(self) or return false
      say :ask, :q => text
      true
    end

    def answered_q q
      got or return false
      qs_answers[q.key] = got
      handled!
      true
    end

    def send_msg a
      text = a.interpolate(self) or return false
      say :message, :msg => text
      true
    end

    def assign a
      text = a.interpolate(self) or return false
      say :assignment, :msg => text
      true
    end

    def complete_assign a = nil
      got or return false
      if recognized == :done
        say :ok
        handled!
        true
      else
        cb :did_report
        handled!
        false
      end
    end

    def null_assign
      say :proceed
      true
    end

    def finish
      true
    end
  end
end
