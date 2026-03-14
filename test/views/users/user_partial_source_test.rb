require "test_helper"

class Users::UserPartialSourceTest < ActiveSupport::TestCase
  test "remove translation calls use ruby string literals" do
    source = File.read(Rails.root.join("app/views/users/_user.html.erb"))

    assert_includes source, 'turbo_confirm: t(".confirm_remove"), confirm_verb: t("common.remove")'
    assert_includes source, 't(".remove_from_account", name: user.name)'
  end
end
