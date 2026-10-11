# Helpers for rendering account forms.
module AccountsHelper
  # Options for selecting a person, group, or external account owner.
  # @return [Array<Array(String, String)>]
  def managed_owner_options
    people = Person.order(:name).map do |person|
      [ t("accounts.form.person_owner", name: person.name), "person_#{person.id}" ]
    end
    groups = Group.order(:name).map do |group|
      [ t("accounts.form.group_owner", name: group.name), "group_#{group.id}" ]
    end
    [ [ t("accounts.form.external_owner"), "" ], *people, *groups ]
  end
end
