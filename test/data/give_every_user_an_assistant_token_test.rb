require "test_helper"
require_relative "../../db/data/20260821100000_give_every_user_an_assistant_token"

class GiveEveryUserAnAssistantTokenTest < ActiveSupport::TestCase
  test "a user who existed before assistants did gets a token" do
    user = users(:member)
    user.update_columns(assistant_token: nil)

    GiveEveryUserAnAssistantToken.new.up

    assert_not_nil user.reload.assistant_token
  end

  test "a user who already has a token keeps it" do
    user = users(:member)
    user.regenerate_assistant_token
    token = user.assistant_token

    GiveEveryUserAnAssistantToken.new.up

    assert_equal token, user.reload.assistant_token
  end
end
