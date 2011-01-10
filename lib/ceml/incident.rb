require 'set'

module CEML
  class Incident
    attr_reader :script, :id, :players
    def this;       @players[@current_id]; end
    def roles;      this[:roles] ||= Set.new; end
    def got;        this[:received];   end
    def recognized; this[:recognized]; end
    def pc;         this[:pc] ||= 0;   end
    def qs_answers; this[:qs_answers] ||= Hash.new; end

    def initialize(script, cast = {}, id = rand(36**10).to_s(36))
      @id = id
      @script = Script === script ? script : CEML.parse(:script, script)
      run do
        cast.each{ |guy,role| add guy, role }
      end
    end

    def add(id, *roles)
      obj = Hash === roles[-1] ? roles.pop : {}
      @players[id] = obj.merge :roles => Set.new(roles)
    end

    def run
      CEML.delegate.with_players(@id) do |players|
        @players = players
        yield self if block_given?
        :loop while players.keys.any? do |@current_id|
          # puts "seq for roles: #{roles.inspect} #{seq.inspect}"
          # puts "trying: #{@current_id}: #{seq[pc]}"
          next unless seq[pc] and send(*seq[pc])
          CEML.delegate.send(*seq[pc] + [@iid, @current_id])
          this[:pc]+=1
        end
        @players = nil
      end
    end

    def seq
      @seq ||= {}
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
      @players.each do |key, thing|
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
        CEML.delegate.send :did_report
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
