require "test_helper"

class SessionTest < ActiveSupport::TestCase
  # -- start! -----------------------------------------------------------------

  test "start! creates a new session for the user" do
    user = users(:admin)

    assert_difference("Session.count", 1) do
      user.sessions.start!(user_agent: "TestBrowser", ip_address: "192.168.1.1")
    end
  end

  test "start! persists user_agent and ip_address" do
    session = users(:admin).sessions.start!(user_agent: "TestBrowser", ip_address: "192.168.1.1")

    assert_equal "TestBrowser", session.user_agent
    assert_equal "192.168.1.1", session.ip_address
  end

  test "start! sets last_active_at on creation" do
    session = users(:admin).sessions.start!(user_agent: "TestBrowser", ip_address: "192.168.1.1")

    assert_not_nil session.last_active_at
  end

  # -- resume -----------------------------------------------------------------

  test "resume updates activity when last active more than ACTIVITY_REFRESH_RATE ago" do
    session = sessions(:admin_session)
    session.update_column(:last_active_at, 2.hours.ago)

    session.resume(user_agent: "UpdatedBrowser", ip_address: "10.0.0.1")

    assert_equal "UpdatedBrowser", session.reload.user_agent
    assert_equal "10.0.0.1", session.ip_address
  end

  test "resume does not update when last active within ACTIVITY_REFRESH_RATE" do
    session = sessions(:admin_session)
    session.update_column(:last_active_at, 30.minutes.ago)
    old_agent = session.user_agent

    session.resume(user_agent: "UpdatedBrowser", ip_address: "10.0.0.1")

    assert_equal old_agent, session.reload.user_agent
  end

  # -- has_secure_token -------------------------------------------------------

  test "session generates a token" do
    session = users(:admin).sessions.start!(user_agent: "TestBrowser", ip_address: "192.168.1.1")

    assert_not_nil session.token
  end

  # -- ACTIVITY_REFRESH_RATE constant -----------------------------------------

  test "ACTIVITY_REFRESH_RATE is 1 hour" do
    assert_equal 1.hour, Session::ACTIVITY_REFRESH_RATE
  end
end
