# Answers Model Context Protocol requests, so an assistant can read and update the books
#
# The caller identifies itself with the assistant token of the user it acts for.
class AssistantController < ActionController::API
  before_action :ensure_home_network
  before_action :authenticate_assistant

  # Dispatches one protocol request to the assistant's tools
  #
  # @action POST
  # @route /mcp
  def create
    status, headers, body = transport.handle_request(request)

    headers.each { |name, value| response.set_header(name, value) }
    render json: body.first, status: status
  end

  private

  # Asked from anywhere else, the app says only that it will not answer: confirming that a token
  # is wanted, and reading the one presented, are both things the home network alone gets to see.
  def ensure_home_network
    home_network = Rails.configuration.x.assistant_host
    return if home_network.blank?

    head :forbidden unless request.host == home_network
  end

  def authenticate_assistant
    token = presented_token
    return head :unauthorized if token.blank?

    head :unauthorized unless User.active.exists?(assistant_token: token)
  end

  def presented_token
    request.headers["Authorization"].to_s.delete_prefix("Bearer ").presence
  end

  def transport
    MCP::Server::Transports::StreamableHTTPTransport.new(
      server,
      stateless: true,
      enable_json_response: true,
      serve_subscriptions_listen: false,
      allowed_hosts: Array(Rails.configuration.x.assistant_host)
    )
  end

  def server
    MCP::Server.new(name: "journal_administration", tools: tools)
  end

  def tools
    [
      Assistant::AddAccountAlias,
      Assistant::FindAccounts,
      Assistant::FindUncategorizedTransactions,
      Assistant::ListCategories,
      Assistant::SetTransactionCategory
    ]
  end
end
