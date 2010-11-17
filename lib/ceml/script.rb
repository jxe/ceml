module CEML
  module Script

    def to_hash *fields
      fields.inject({}){ |h, s| x = send(s); h[s] = x if x; h }
    end

    def script
      text_value
    end

    def title
      super && !super.empty? && super.value
    end

    def name
      title || label
    end

    def radius
      casting_statement.empty? ? nil : casting_statement.radius
    end

    def roles
      return [:agents] if casting_statement.empty?
      return casting_statement.roles
    end

    def dramatis_personae
      casting_statement.empty? ? nil : casting_statement
    end

    alias_method :dp, :dramatis_personae

    def simple?
      (roles - [:agents, :organizer]).empty?
    end

    def expand_roles(roles)
      roles.map{ |r| r == :agent ? [:agent, :agents] : r }.flatten.concat([:both, :all, :everyone])
    end

    def instructions_for(roles)
      return [] if !instructions or instructions.empty?
      return instructions.for(expand_roles(roles))
    end

    def asks(roles)
      return [] if instructions.empty?
      instructions.asks([*roles])
    end

    def params
      asks(:organizer).map do |ask|
        [ask.var, ask.var.capitalize, ask.text]
      end
    end

    def tell(roles)
      return nil if instructions.empty?
      instructions.tell([*roles])
    end

    def type
      return 'mission'  if title
      return 'unknown'  if instructions.empty?
      return 'question' if not instructions.asks.empty?
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

    def validate!
      instructions.validate!(allowed_roles) unless instructions.empty?
    end

    def allowed_roles
      allowed_roles = [:organizer, :agents]
      allowed_roles += casting_statement.roles unless casting_statement.empty?
      allowed_roles
    end

    def concludes_immediately?
      !title and instructions.asks([:agents]).empty?
    end

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
      odds       = likelihood(yesprob, potential_count, needed)

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

  end
end
