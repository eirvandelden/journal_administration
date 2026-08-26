module ApplicationCable
  class Connection < ActionCable::Connection::Base
    include Appkit::Authentication::SessionLookup

    identified_by :current_user

    def connect
      session = find_session_by_cookie
      reject_unauthorized_connection unless session

      self.current_user = session.user
    end
  end
end
