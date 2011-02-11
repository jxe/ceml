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

    def role_info
      { :is_transient => is_transient? }
    end

    def is_transient?
      main_seq.none? do |opcode, arg|
        case opcode
        when :start_delay, :ask_q, :assign, :null_assign then true
        end
      end
    end

    def main_seq
      bytecode = []
      instrs = script.instructions_for(roles)
      instrs.each do |inst|
        if inst.delay
          bytecode << [:start_delay, inst.delay]
          bytecode << [:complete_delay]
        end
        case inst.cmd
        when :record
          bytecode << [:answered_q, {:key => inst.key}]
        when :set
          bytecode << [:set, {:key => inst.key, :value => inst.text}]
        when :ask
          bytecode << [:ask_q, {:text => inst.text}]
          bytecode << [:answered_q, {:key => inst.key}]
        when :tell
          bytecode << [:send_msg, {:text=>inst.text}]
        when :assign
          bytecode << [:assign, {:text=>inst.text}]
          bytecode << [:complete_assign, {:text=>inst.text}]
        end
      end
      if instrs.empty? and script.title
        bytecode << [:null_assign]
        bytecode << [:complete_assign]
      end
      bytecode
    end

    def seq
      @seq ||= {}
      @seq[roles] ||= begin
        bytecode = [[:start, role_info]]
        bytecode.concat main_seq
        bytecode << [:finish]
      end
    end

    def expand(role, var)
      case role
      when 'his', 'her', 'their';                 return qs_answers[var]
      when 'world', 'game', 'exercise', 'group';  return (cb :world, var)
      when 'somebody', 'someone', 'buddy';        role = nil
      end
      role = role.to_sym if role
      @players.each do |p|
        next if p == this
        next if role and not p[:roles].include? role
        value = (p[:qs_answers]||{})[var] and return value
      end
      nil
    end

    INTERPOLATE_REGEX = /\|(\w+)\.?(\w+)?\|/

    def interpolate(text)
      text =~ INTERPOLATE_REGEX or return text
      text.gsub(INTERPOLATE_REGEX) do |m|
        var, role = *[$2, $1].compact
        expand(role, var) or return false
      end
    end


    # ==============
    # = basic flow =
    # ==============

    def say x, params = {}
      cb :said, params.merge(:said => x)
    end

    def start(x); true; end
    def finish; true; end

    def start_delay seconds
      this[:continue_at] = CEML.clock + seconds
      true
    end

    def complete_delay
      return false unless CEML.clock >= this[:continue_at]
      this.delete(:continue_at)
      true
    end
    
    def sync
      # mark self as ready to continue
      # continue only if all players with roles are marked ready
      # clear marks
      # continue
    end
    
    def ask_q q
      text = interpolate(q[:text]) or return false
      say :ask, :q => text
      true
    end

    def answered_q q
      got or return false
      qs_answers[q[:key]] = got
      handled!
      true
    end

    def set q
      qs_answers[q[:key]] = q[:value]
      true
    end

    def send_msg a
      text = interpolate(a[:text]) or return false
      say :message, :msg => text
      true
    end

    def assign a
      text = interpolate(a[:text]) or return false
      say :assignment, :msg => text
      true
    end

    def complete_assign a = nil
      got or return false
      if recognized == :done
        cb :did_complete
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
  end
end
