if Rails.env.development? && ENV["BYEBUGPORT"]
  require "byebug/core"
  Byebug.start_server "localhost", ENV["BYEBUGPORT"].to_i
end
