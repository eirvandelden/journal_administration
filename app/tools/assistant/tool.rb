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

    def self.backwards(first_day, last_day)
      "A period cannot end before it starts, and #{last_day} comes before #{first_day}."
    end
    private_class_method :backwards

    # Read a day strictly rather than leniently: Date.parse turns "next Monday" into a real day,
    # so loose phrasing would quietly become a period, or a budget, nobody named. The whole text
    # has to be the day, because reading only the front of it accepts "2026-09-08 or next Monday"
    # and silently drops the half that says the assistant was unsure.
    def self.day(text)
      written = text.to_s.strip
      read = Date.strptime(written, "%Y-%m-%d")

      read if read.strftime("%Y-%m-%d") == written
    rescue Date::Error
      nil
    end
    private_class_method :day
  end
end
