module CEML
  module Script
    extend Forwardable

    # ===========
    # = casting =
    # ===========

    def fits? candidate
      roles_to_cast.any?{ |r| r.fits? candidate }
    end

    def roles_to_cast
      return [] unless cast.type == :await
      return cast.roles_to_cast(self)
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
      return casting_statement if respond_to? :casting_statement
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
      allowed_roles = [:organizer, :agents, :both, :all, :everyone, :each, :players]
      allowed_roles += cast.rolenames
      allowed_roles.uniq
    end


    # ================
    # = instructions =
    # ================

    def instructions
      return self if Instructions === self
      return super if defined?(super)
      nil
    end

    def instructions_for(roles)
      return [] unless instructions
      return instructions.for(expand_roles(roles))
    end

    def bytecode
      code = [[[:all], :start]]
      return [[[:all], :null_assign], [[:all], :complete_assign]] if !instructions and title
      instructions.list.each{ |inst| code.concat inst.bytecode } if instructions
      code << [[:all], :finish]
      code
    end

    def asks(roles)
      return [] unless instructions
      instructions.i_asks([*roles])
    end

    def tell(roles)
      return unless instructions
      instructions.i_tell([*roles])
    end

    def validate!
      return unless instructions
      instructions.validate_instructions!(allowed_roles)
    end

    def concludes_immediately?
      !title and instructions.asks([:agents]).empty?
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

    def title
      if defined?(super)
        super.title_value
      elsif respond_to? :title_value
        self.title_value
      else nil
      end
    end

    def name
      title || label
    end

    def params
      asks(:organizer).map do |ask|
        [ask.var, ask.var.capitalize, ask.text]
      end
    end

    def type
      return 'mission'  if title
      return 'unknown'  if instructions.empty?
      return 'question' if not instructions.asks(:agents).empty?
      return 'message'  if instructions.tell(:agents)
      return 'unknown'
    end

    def message?
      type == 'message'
    end

    def label
      return title || begin
        return "unknown" unless simple?
        if q = instructions.asks(:agents).first
          "Question: #{q.text}"
        elsif tell = instructions.tell(:agents)
          "Message: #{tell}" if tell
        else
          "unknown"
        end
      end
    end
  end
end
