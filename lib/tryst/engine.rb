module Tryst
  class Engine < Coordinator
    extend Forwardable
    attr_reader :script
    def_delegators :script, :title, :tell
    def got;        this[:received];   end
    def recognized; this[:recognized]; end

    def initialize(script_text, delegate = nil)
      @script = Tryst.parse(:script, script_text)
      @delegate = delegate
      super({})
    end

    def add(id, *states)
      obj = Hash === states[-1] ? states.pop : {}
      elements[id] = obj.merge :states => Set.new(states)
    end

    def pass meth
      return unless @delegate
      @delegate.send(meth, self) if @delegate.respond_to? meth
    end

    # TODO
    def roles
      [script.roles.first, states.include?(:organizer) && :organizer, :agents, :both, :all, :everyone]
    end

    def say x, params = {}
      this[:said] = x
      this.merge! params
    end


    # ==============
    # = basic flow =
    # ==============

    tasks :agent => [
      :setup_agent,
      :send_all_messages,
      :answer_all_questions,
      :send_assignment,
      :complete_assignment
    ]

    def setup_agent
      states.merge case script.type
      when 'question'; [:send_assignment, :complete_assignment, :send_all_messages]
      when 'message';  [:send_assignment, :complete_assignment, :answer_all_questions]
      else [:send_all_messages]
      end
      pass :did_initialize
      true
    end


    # =============
    # = questions =
    # =============

    def qs;          script.asks(roles);   end
    def qs_asked;    this[:qs_asked]    ||= Set.new; end
    def qs_answered; this[:qs_answered] ||= Set.new; end
    def qs_answers;  this[:qs_answers]  ||= Hash.new; end
    def next_q;      qs.detect{ |q| !qs_asked.include?(q.key) }; end
    def open_q;      qs.detect{ |q| qs_asked.include?(q.key) && !qs_answered.include?(q.key) }; end

    def answer_all_questions
      if got and q = open_q
        qs_answers[q.key] = got
        pass :did_answer
      end

      if q = next_q
        text = q.interpolate(self)
        text and say :ask, :q => text
        pass :did_ask
        false
      else
        true
      end
    end


    # =========================
    # = interpolating answers =
    # =========================

    def expand(role, var)
      role = nil if role == 'otherguy'
      elements.each do |key, thing|
        next if key == @current_id
        next if role and not thing[:states][role]
        value = thing[:qs_answers][var] and return value
      end
      nil
    end


    # ============
    # = messages =
    # ============

    def send_all_messages
      puts "send_all_msgs"
      return true unless text = script.tell(roles).interpolate(self)
      say :message, :msg => text
      pass :did_message
      return true
    end


    # ===============
    # = assignments =
    # ===============

    def send_assignment
      did :answer_all_questions or return false

      if title and !script.tell(roles)
        comment :proceed
        return true
      end

      text = script.tell(roles).interpolate(self)
      text or return false
      say :assignment, :msg => text
      pass :did_assign
      return true
    end

    def complete_assignment
      did :send_assignment and got or return false

      if recognized == :done
        comment :ok
        return true

      else
        pass :did_report
        return false
      end
    end
  end
end
