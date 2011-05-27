module CEML
  module BasicInstruction

    # TODO: bug right here
    # def role;  id.respond_to?(:text_value) && id.text_value.to_sym || :none; end
    def role;
      if id.respond_to?(:text_value)
        id.text_value.to_sym
      else
        raise "holy fuck"
      end
    end

    def roles
      [role]
    end

    def text_block
      defined?(:text) && text.text_value
    end
    def var
        return varname.text_value if cmd == :record or cmd == :set or cmd == :release
        (!respond_to?(:about) || about.empty?) ? nil : about.varname.text_value;
    end
    def key;   var || text_block; end
    def cmd;  text_value.split.first.to_sym; end
    def cond
        (!respond_to?(:condition) || condition.empty?) ? nil : condition.value
    end

    def bytecode
        code = []
        code.concat case cmd
        when :record;  [[roles, :answered_q,      {:key  => key}]]
        when :set;     [[roles, :set,             {:key  => key, :value => text_block}]]
        when :pick;    [[roles, :pick,            {:key  => key, :value => text_block}]]
        when :ask;     [[roles, :ask_q,           {:text => text_block, :q => key}],
                        [roles, :answered_q,      {:key  => key}]]
        when :tell;    [[roles, :send_msg,        {:text => text_block}]]
        when :assign;  [[roles, :assign,          {:text => text_block}],
                        [roles, :complete_assign, {:text => text_block}]]
        when :release; [[roles, :release,         {:cond => cond}]]
        when :sync;    [[roles, :sync,            {:role => role}]]
        end
        code
    end

  end
end
