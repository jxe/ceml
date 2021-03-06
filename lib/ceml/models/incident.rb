require 'set'

module CEML
  class Incident
    attr_reader :seq, :id, :this
    def initialize(seq, id); @id = id; @seq = seq; end

    def roles;      this[:roles] ||= Set.new; end
    def got;        this[:received];   end
    def recognized; this[:recognized]; end
    def pc;         this[:pc] ||= 0;   end
    def qs_answers; this[:qs_answers] ||= Hash.new; end

    def handled!
      this.delete :received
      this.delete :recognized
    end

    def cb *stuff
      @callback.call this, *stuff if @callback
    end

    def rolematch(specified_roles)
      expanded = roles.to_a.concat(GENERIC_ROLES)
      not (expanded & [*specified_roles]).empty?
    end

    def log state
      p = @this
      instr = seq[pc]
      guyroles = roles.to_a - GENERIC_ROLES
      instr ||= []

      case state
      when 'completed'
        CEML.log 3, "#{p[:id]}: #{instr[1]}(#{pc}) #{guyroles}/#{instr[0]} ##{id}"
      when 'blocked'
        CEML.log 3, "#{p[:id]}: WAITING FOR #{instr[1]}(#{pc}) #{guyroles}/#{instr[0]} ##{id}"
      else
        CEML.log 3, "#{p[:id]}: #{state} #{instr[1]}/#{instr[0]} -- ##{pc}(#{guyroles}) ##{id}"
      end
      CEML.log 3, "      #{instr[2].inspect}"  if instr[2] and !instr[2].empty?
    end

    def run(players, &blk)
      @players = players
      @callback = blk
      was_blocked = {}
      # CEML.log 1, "running players: #{players.inspect}"

      loop do
        players = @players
        advanced = false
        players.each do |p|
          @this = p
          instr = seq[pc]
          # log "running: #{pc}: #{instr.inspect}"
          unless instr = seq[pc]
            @players.delete(p)
            next
          end
          instr = instr.dup
          rolespec = instr.shift
          if not rolematch(rolespec)
            # log "skipping[#{rolespec}]"
            this[:pc]+=1
            advanced = true
          else
            instr << role_info if instr.first == :start  #tmp hack
            if send(*instr)
              log 'completed'
              was_blocked[p] = false
            else
              log 'blocked' unless was_blocked[p]
              was_blocked[p] = true
              next
            end
            cb(*instr)
            this[:pc]+=1
            advanced = true
          end
        end
        break unless advanced
      end

      @callback = @players = nil
    end

    def role_info
      { :is_transient => is_transient? }
    end

    def is_transient?
      seq.none? do |roles, opcode, arg|
        case opcode
        when :start_delay, :ask_q, :assign, :null_assign then true
        end
      end
    end

    def players_with_role(role)
      if role
        @players.select{ |p| p[:roles].include? role }
      else
        @players.reject{ |p| p == this }
      end
    end

    def expand(role, var)
      case role
      when 'his', 'her', 'their', 'my', 'its', 'your';    return qs_answers[var]
      when 'world', 'game', 'exercise', 'group';  return (cb :world, var)
      when 'somebody', 'someone', 'buddy', 'teammate';  role = nil
      end
      role = role.to_sym if role
      players_with_role(role).each do |p|
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

    def seed x
      x[:rolemap].each do |pair|
        if rolematch(pair[:from].to_sym)
          cb :seeded, :target => x[:target], :role => pair[:to]
          break
        end
      end
      true
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

    def sync q
      this[:synced] = pc
      return true if players_with_role(q[:role]).all?{ |p| p[:synced] == pc }
    end

    def ask_q q
      text = interpolate(q[:text]) or return false
      handled!
      say :ask, :q => text
      true
    end

    def answered_q q
      got or return false
      this[:last_answer] = qs_answers[q[:key]] = got
      this[:last_answer_recognized] = recognized
      handled!
      true
    end

    def set q
      qs_answers[q[:key]] = q[:value]
      true
    end

    def pick q
      choices = q[:value].split(/\s+\-\s+/)
      qs_answers[q[:key]] ||= choices.sort_by{ rand }.first
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
        handled!
        say :ok if pc == seq.size - 2
        true
      else
        cb :did_report
        handled!
        false
      end
    end

    def last_answer_match?(value)
      case value
      when :yes; this[:last_answer_recognized] == :yes
      when :no;  this[:last_answer_recognized] == :no
      end
    end

    def expectation(type, value)
      if type == :if then last_answer_match?(value) else !last_answer_match?(value) end
    end

    def release x
      return true if x[:cond] and not expectation(*x[:cond])
      @players.delete(this)
      cb :released, x[:tag]
      true
    end

    def replace x
      return true if x[:cond] and not expectation(*x[:cond])
      # TODO: implement replace
      false
    end

    def null_assign
      say :proceed
      true
    end
  end
end
