class BackfillUnicodeNameKeys < ActiveRecord::Migration[8.1]
  class PersonRecord < ActiveRecord::Base
    self.table_name = "people"
  end

  class GroupRecord < ActiveRecord::Base
    self.table_name = "groups"
  end

  def up
    PersonRecord.find_each { |person| person.update_columns(name_key: person.name.downcase) }
    GroupRecord.find_each { |group| group.update_columns(name_key: group.name.downcase) }
  end

  def down
    PersonRecord.update_all(name_key: nil)
    GroupRecord.update_all(name_key: nil)
  end
end
