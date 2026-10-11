class MigratePeopleGroupsAndLegacyOwners < ActiveRecord::Migration[8.1]
  class AccountRecord < ActiveRecord::Base
    self.table_name = "accounts"
  end

  class PersonRecord < ActiveRecord::Base
    self.table_name = "people"
  end

  class GroupRecord < ActiveRecord::Base
    self.table_name = "groups"
  end

  class GroupMembershipRecord < ActiveRecord::Base
    self.table_name = "group_memberships"
  end

  class AppropriationRecord < ActiveRecord::Base
    self.table_name = "appropriations"
  end

  LEGACY_OWNERS = {
    0 => "Samen",
    1 => "Etienne",
    2 => "Michelle",
    3 => "Serena",
    4 => "Cosimo",
    5 => "Chiara"
  }.freeze

  def up
    owners = AccountRecord.where.not(owner: nil).distinct.pluck(:owner)
    owners.each { |owner| person_for(LEGACY_OWNERS.fetch(owner), household: true) unless owner.zero? }

    etienne = person_for("Etienne", household: true)
    michelle = person_for("Michelle", household: true)
    samen = group_for("Samen")
    membership_for(samen, etienne)
    membership_for(samen, michelle)

    AccountRecord.where(owner: 0).update_all(group_id: samen.id)
    LEGACY_OWNERS.except(0).each do |owner, name|
      person = person_for(name, household: true)
      AccountRecord.where(owner: owner).update_all(person_id: person.id)
    end

    AppropriationRecord.order(:id).each do |appropriation|
      person = person_for(appropriation.recipient, household: false)
      appropriation.update_columns(person_id: person.id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def person_for(name, household:)
    person = PersonRecord.all.find { |entry| entry.name.casecmp?(name) }
    person ||= PersonRecord.new
    person.name = name if person.new_record?
    person.household = true if household
    person.save! if person.new_record? || person.changed?
    person
  end

  def group_for(name)
    group = GroupRecord.all.find { |entry| entry.name.casecmp?(name) }
    group ||= GroupRecord.new
    group.name = name if group.new_record?
    group.save! if group.new_record? || group.changed?
    group
  end

  def membership_for(group, person)
    GroupMembershipRecord.find_or_create_by!(group_id: group.id, person_id: person.id)
  end
end
