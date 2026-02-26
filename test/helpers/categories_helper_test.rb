require "test_helper"

class CategoriesHelperTest < ActionView::TestCase
  include CategoriesHelper

  test "grouped_category_options builds named parents group first and per-parent child groups" do
    html = grouped_category_options
    groceries = categories(:groceries)
    housing = categories(:housing)
    supermarket = categories(:supermarket)

    # Ensure named first group exists with the i18n label
    main_group_label = I18n.t("categories.main")
    assert_includes html, "<optgroup label=\"#{main_group_label}\">"

    # Ensure parents in alphabetical order
    first_group_start = html.index("<optgroup label=\"#{main_group_label}\">")
    first_group_end = html.index("</optgroup>", first_group_start)
    first_group = html[first_group_start..first_group_end]
    assert first_group.index(">#{groceries.name}</option>") < first_group.index(">#{housing.name}</option>"),
"Parents not sorted alphabetically"

    # Ensure child groups exist labeled by parent
    assert_includes html, "<optgroup label=\"#{groceries.name}\">"
    assert_includes html, "<optgroup label=\"#{housing.name}\">"

    # Groceries has a single child Supermarket
    groceries_group_start = html.index("<optgroup label=\"#{groceries.name}\">")
    groceries_group_end = html.index("</optgroup>", groceries_group_start)
    groceries_group = html[groceries_group_start..groceries_group_end]
    assert_includes groceries_group, ">#{supermarket.name}</option>"

    # Ensure child option labels are only child names (not full names)
    assert_not_includes groceries_group, "#{groceries.name} - #{supermarket.name}"
  end
end
