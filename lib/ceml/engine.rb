require 'set'

module CEML
  class Dummy
    def method_missing(meth, *args, &blk)
      # puts "#{meth}: #{args.to_s.inspect}"
    end
  end

  class Engine
    attr_reader :script, :parts
    def this;       @parts[@current_id]; end
    def roles;      this[:roles] ||= Set.new; end
    def got;        this[:received];   end
    def recognized; this[:recognized]; end
    def pc;         this[:pc] ||= 0;   end
    def qs_answers; this[:qs_answers] ||= Hash.new; end

    def initialize(script_text, delg = Dummy.new)
      @script = CEML.parse(:script, script_text)
      @delg   = delg
      @parts  = {}
      @seq    = {}
    end

    def add(id, *roles)
      obj = Hash === roles[-1] ? roles.pop : {}
      parts[id] = obj.merge :roles => Set.new(roles)
    end

    def run
      :loop while parts.keys.any? do |@current_id|
        # puts "trying: #{@current_id}: #{seq[pc]}"
        next unless seq[pc] and send(*seq[pc])
        @delg.send(*seq[pc] + [@current_id])
        this[:pc]+=1
      end
    end

    def seq
      @seq[roles] ||= begin
        bytecode = [[:start]]
        instrs = script.instructions_for(roles)
        instrs.each do |inst|
          case inst.cmd
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

    def say x, params = {}
      this[:said] = x
      this.merge! params
    end

    def expand(role, var)
      role = nil if role == 'otherguy'
      role = role.to_sym if role
      parts.each do |key, thing|
        next if key == @current_id
        next if role and not thing[:roles].include? role
        value = (thing[:qs_answers]||{})[var] and return value
      end
      nil
    end

    # ==============
    # = basic flow =
    # ==============

    def start
      roles.include? :agent or return false
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
        true
      else
        @delg.send :did_report
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
