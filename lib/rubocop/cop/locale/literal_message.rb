require "rubocop"

module RuboCop
  module Cop
    module Locale
      # Reports a string literal with a letter passed as a flash, notice, alert, validation or errors.add message.
      class LiteralMessage < Base
        MSG = "Use a translation key for a user-facing message, not a literal string.".freeze
        RESTRICT_ON_SEND = %i[[]= notice= alert= add].freeze
        MESSAGE_KEYS = %i[notice alert message].freeze
        MESSAGE_VARIABLES = %i[notice alert @notice @alert].freeze

        # Reports flash[:x] = "...", flash.now[:x] = "...", flash.notice = "...", flash.now.alert = "..."
        # and errors.add(:attr, "...").
        #: (RuboCop::AST::SendNode node) -> void
        def on_send(node)
          message = flash_index_assignment?(node) || flash_writer?(node) || errors_add?(node)
          report(message)
        end

        # Reports notice: "...", alert: "..." and message: "..." in any call.
        #: (RuboCop::AST::PairNode node) -> void
        def on_pair(node)
          report(node.value) if node.key.sym_type? && MESSAGE_KEYS.include?(node.key.value)
        end

        # Reports notice = "..." and alert = "..." assigned to a local or instance variable.
        #: (RuboCop::AST::AsgnNode node) -> void
        def on_lvasgn(node)
          name, value = *node
          report(value) if MESSAGE_VARIABLES.include?(name)
        end
        alias on_ivasgn on_lvasgn

        private

        # @!method flash_index_assignment?(node)
        def_node_matcher :flash_index_assignment?, <<~PATTERN
          (send {(send nil? :flash) (send (send nil? :flash) :now)} :[]= _ $_)
        PATTERN

        # @!method flash_writer?(node)
        def_node_matcher :flash_writer?, <<~PATTERN
          (send {(send nil? :flash) (send (send nil? :flash) :now)} {:notice= :alert=} $_)
        PATTERN

        # @!method errors_add?(node)
        def_node_matcher :errors_add?, <<~PATTERN
          (send (send _ :errors) :add _ $_ ...)
        PATTERN

        private :flash_index_assignment?, :flash_writer?, :errors_add?

        def report(node)
          add_offense(node) if node && literal_with_letter?(node)
        end

        def literal_with_letter?(node)
          return false unless node.str_type? || node.dstr_type?

          literal_text(node).match?(/\p{L}/)
        end

        def literal_text(node)
          return node.value if node.str_type?

          node.children.filter_map { |child| child.value if child.str_type? }.join
        end
      end
    end
  end
end
