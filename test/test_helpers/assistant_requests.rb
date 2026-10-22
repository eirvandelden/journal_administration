# Talks to the assistant endpoint from an integration test
#
# The including test sets up its own host and token: `host! "localhost"`, a user, and
# `regenerate_assistant_token`.
module AssistantRequests
  private

  def ask_assistant(tool, arguments = {})
    post_to_assistant(method: "tools/call", params: { name: tool, arguments: arguments })

    assert_response :success
    JSON.parse(response.body).dig("result", "content").map { |part| part["text"] }.join("\n")
  end

  def refused?(tool, arguments = {})
    post_to_assistant(method: "tools/call", params: { name: tool, arguments: arguments })

    JSON.parse(response.body).dig("result", "isError").present?
  end

  def post_to_assistant(method: "tools/list", params: {}, token: @user.assistant_token, headers: {})
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: method, params: params }.to_json,
      headers: assistant_headers(token: token).merge(headers)
  end

  def assistant_headers(token: @user.assistant_token)
    headers = { "Content-Type" => "application/json", "Accept" => "application/json" }
    headers["Authorization"] = "Bearer #{token}" if token
    headers
  end
end
