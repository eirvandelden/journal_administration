# Common ground for everything an assistant may do to the books
module Assistant
  class Tool < MCP::Tool
    def self.answer(message)
      MCP::Tool::Response.new([ { type: "text", text: message } ])
    end
    private_class_method :answer

    def self.problem(message)
      MCP::Tool::Response.new([ { type: "text", text: message } ], error: true)
    end
    private_class_method :problem

    # Read a day strictly rather than leniently: Date.parse turns "next Monday" into a real day,
    # so loose phrasing would quietly become a period, or a budget, nobody named.
    def self.day(text)
      Date.strptime(text.to_s, "%Y-%m-%d")
    rescue Date::Error
      nil
    end
    private_class_method :day
  end
end
