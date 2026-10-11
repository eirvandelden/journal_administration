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
    samen = household_group
    AccountRecord.where(owner: 0).update_all(group_id: samen.id)
    legacy_person_owners.each do |owner|
      person = person_for(LEGACY_OWNERS.fetch(owner), household: true)
      AccountRecord.where(owner: owner).update_all(person_id: person.id)
    end

    link_appropriations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def household_group
    samen = group_for("Samen")
    membership_for(samen, person_for("Etienne", household: true))
    membership_for(samen, person_for("Michelle", household: true))
    samen
  end

  def group_for(name)
    group = GroupRecord.all.find { |entry| entry.name.downcase == name.downcase }
    group ||= GroupRecord.new
    group.name = name if group.new_record?
    group.save! if group.new_record? || group.changed?
    group
  end

  def membership_for(group, person)
    GroupMembershipRecord.find_or_create_by!(group_id: group.id, person_id: person.id)
  end

  def person_for(name, household:)
    person = PersonRecord.all.find { |entry| entry.name.downcase == name.downcase }
    person ||= PersonRecord.new
    person.name = name if person.new_record?
    person.household = true if household
    person.save! if person.new_record? || person.changed?
    person
  end

  def legacy_person_owners
    AccountRecord.where.not(owner: [ nil, 0 ]).distinct.order(:owner).pluck(:owner)
  end

  # Links each appropriation to its person; a later case variant with the same
  # purpose and year stays unlinked, because the unique index allows one.
  def link_appropriations
    linked = Set.new
    AppropriationRecord.order(:id).each do |appropriation|
      person = person_for(appropriation.recipient, household: false)
      next unless linked.add?([ person.id, appropriation.purpose.to_s.downcase(:ascii), appropriation.budget_year ])

      appropriation.update_columns(person_id: person.id)
    end
  end
end
