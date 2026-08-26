require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "someone signed in is recognised on the live connection" do
    session = sessions(:member_session)
    cookies.signed[:session_token] = session.token

    connect

    assert_equal session.user, connection.current_user
  end

  test "someone who is not signed in is refused a live connection" do
    assert_reject_connection { connect }
  end

  test "a session token that belongs to nobody is refused" do
    cookies.signed[:session_token] = "not-a-real-token"

    assert_reject_connection { connect }
  end
end
