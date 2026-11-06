class GiveEveryUserAnAssistantToken < ActiveRecord::Migration[8.1]
  #: () -> void
  def up
    User.where(assistant_token: nil).find_each(&:regenerate_assistant_token)
  end

  #: () -> void
  def down
    User.update_all(assistant_token: nil)
  end
end
