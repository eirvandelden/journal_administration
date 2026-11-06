# Common ground for everything an assistant may do to the books
module Assistant
  class Tool < MCP::Tool
    #: (String message) -> MCP::Tool::Response
    def self.answer(message)
      MCP::Tool::Response.new([ { type: "text", text: message } ])
    end
    private_class_method :answer

    #: (String message) -> MCP::Tool::Response
    def self.problem(message)
      MCP::Tool::Response.new([ { type: "text", text: message } ], error: true)
    end
    private_class_method :problem

    # Cents as euros with two decimals, the way assistants have always been told amounts
    #: (Integer cents) -> String
    def self.euros(cents) = format("%.2f", Cents.to_euros(cents))
    private_class_method :euros

    # The cents in an amount the assistant sent in euros, or nil when it has a fraction of a cent
    #: (Numeric amount) -> Integer?
    def self.cents_from(amount)
      Cents.from_euros(amount)
    rescue ArgumentError
      nil
    end
    private_class_method :cents_from

    #: () -> String
    def self.two_decimals
      "An amount has at most two decimals, for example 12.50."
    end
    private_class_method :two_decimals

    #: (Date first_day, Date last_day) -> String
    def self.backwards(first_day, last_day)
      "A period cannot end before it starts, and #{last_day} comes before #{first_day}."
    end
    private_class_method :backwards

    # Read a day strictly rather than leniently: Date.parse turns "next Monday" into a real day,
    # so loose phrasing would quietly become a period, or a budget, nobody named. The whole text
    # has to be the day, because reading only the front of it accepts "2026-09-08 or next Monday"
    # and silently drops the half that says the assistant was unsure.
    #: (String? text) -> Date?
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
