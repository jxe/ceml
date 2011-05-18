module CEML
  module Script
    extend Forwardable

    # ===========
    # = casting =
    # ===========

    def castable
      return nil unless cast.type == :await
      args = cast.casting_spec + [bytecode]
      Castable.new(*args)
    end

    def nabs?
      cast.type == :nab or !title
    end


    # ===============
    # = likelihoods =
    # ===============

    def color(odds)
      return :red    if odds < 0.1
      return :yellow if odds < 0.4
      return :green
    end

    def likelihood(yesprob, needed, psize)
      return 1 if needed <= 0
      return 0 if psize < needed
      return (needed..psize).inject(0) do |memo, yes_count|
        memo + begin
          no_count = psize - yes_count
          ways_it_could_happen = psize.choose(yes_count)
          prob_of_each = (yesprob ** yes_count) * ((1 - yesprob) ** no_count)
          ways_it_could_happen * prob_of_each
        end
      end
    end

    def availabilities(potential_count, committed_count = 0)
      return {} unless script.dramatis_personae
      min        = script.dramatis_personae.min
      needed     = min - committed_count
      possible   = potential_count + committed_count
      yesprob    = 0.7  # just make this up for now
      odds       = likelihood(yesprob, needed, potential_count)

      {
        :odds => odds, :color => color(odds),
        :availability_counts => {
          :total => possible,
          :unknown => potential_count
        },
        :estimated_size => yesprob * potential_count + committed_count,
        :needed => min
      }
    end


    # ========
    # = cast =
    # ========

    DefaultDP = Struct.new :radius, :rolenames, :max, :type

    def cast
      return elements.first.casting_statement if elements.first.respond_to? :casting_statement
      return DefaultDP.new nil, [:agents], 0, :gather
    end

    def_delegators :cast, :radius
    def_delegator :cast, :max, :max_to_invite
    def_delegator :cast, :rolenames, :roles
    alias_method :dramatis_personae, :cast
    alias_method :dp, :dramatis_personae

    # casting_statement.roles.names

    def simple?
      (roles - [:agents, :organizer]).empty?
    end

    def expand_roles(roles)
      roles.map{ |r| r == :agent ? [:agent, :agents] : r }.flatten.concat([:both, :all, :everyone])
    end

    def allowed_roles
      allowed_roles = [:organizer, :agents, :both, :all, :everyone, :each, :players, :them, :either]
      allowed_roles += cast.rolenames
      allowed_roles.uniq
    end


    # ================
    # = instructions =
    # ================

    def instructions
      elements.first.instructions if elements.first.respond_to? :instructions
      # return self if Instructions === self
      # return super if defined?(super)
      # nil
    end

    def title
      elements.first.title.title_value if elements.first.respond_to? :title
      # if defined?(super)
      #   super.title_value
      # elsif respond_to? :title_value
      #   self.title_value
      # else nil
      # end
    end


    def bytecode
      code = [[[:all], :start]]
      # puts "instructions: #{instructions.inspect}"
      if !instructions and title
        code.concat [[[:all], :null_assign], [[:all], :complete_assign]]
      elsif instructions
        code.concat(instructions.bytecode.flatten(1))
      end
      code << [[:all], :finish]
      code
    end

    def validate!
      # return unless instructions
      # instructions.validate_instructions!(allowed_roles)
    end

    def concludes_immediately?
      !title and bytecode.none?{ |line| [:assign, :ask_q].include?(line[1]) }
    end


    # =======
    # = etc =
    # =======

    def to_hash *fields
      fields.inject({}){ |h, s| x = send(s); h[s] = x if x; h }
    end

    def script
      text_value
    end

    def name
      title || label
    end

    def params
      bytecode.map do |line|
        next unless line[0].include?(:organizer)
        next unless line[1] == :ask_q
        [line[2][:q], line[2][:q].capitalize, line[2][:text]]
      end.compact
    end

    def type
      return 'mission'  if title
      return 'unknown'  if instructions.empty?
      return 'question' if simple_question
      return 'message'  if simple_message
      return 'unknown'
    end

    def simple_message
      # puts "bytecode size: #{bytecode.size}"
      # p bytecode
      return unless bytecode.size == 3
      # puts "bytecode core: #{bytecode[1][1]}"
      return unless bytecode[1][1] == :send_msg
      return bytecode[1][2][:text]
    end

    def simple_question
      # puts "bytecode size: #{bytecode.size}"
      # p bytecode
      return unless bytecode.size == 4
      # puts "bytecode core: #{bytecode[1][1]}"
      return unless bytecode[1][1] == :ask_q
      return bytecode[1][2][:text]
    end

    def message?
      type == 'message'
    end

    def label
      return title || begin
        return "unknown" unless simple?
        if simple_question
          "Question: #{simple_question}"
        elsif simple_message
          "Message: #{simple_message}"
        else
          "unknown"
        end
      end
    end
  end
end
