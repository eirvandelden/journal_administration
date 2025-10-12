require "test_helper"

class CategoriesHelperTest < ActionView::TestCase
  include CategoriesHelper

  test "grouped_category_options builds named parents group first and per-parent child groups" do
    html = grouped_category_options

    # Ensure nameless first group exists
    assert_includes html, "<optgroup label=\"\">"

    # Ensure parents in alphabetical order
    first_group_start = html.index("<optgroup label=\"\">")
    first_group_end = html.index("</optgroup>", first_group_start)
    first_group = html[first_group_start..first_group_end]
    assert first_group.index(">Abonnementen</option>") < first_group.index(">Boodschappen</option>"), "Parents not sorted alphabetically"

    # Ensure child groups exist labeled by parent
    assert_includes html, "<optgroup label=\"Abonnementen\">"
    assert_includes html, "<optgroup label=\"Boodschappen\">"

    # Abonnementen children sorted: Lezen, Streaming
    abon_group_start = html.index("<optgroup label=\"Abonnementen\">")
    abon_group_end = html.index("</optgroup>", abon_group_start)
    abon_group = html[abon_group_start..abon_group_end]
    assert abon_group.index(">Lezen</option>") < abon_group.index(">Streaming</option>"), "Children not sorted within parent group"

    # Ensure child option labels are only child names (not full names)
    refute_includes abon_group, "Abonnementen - Streaming"

    # Boodschappen has a single child Supermarkt
    boods_group_start = html.index("<optgroup label=\"Boodschappen\">")
    boods_group_end = html.index("</optgroup>", boods_group_start)
    boods_group = html[boods_group_start..boods_group_end]
    assert_includes boods_group, ">Supermarkt</option>"
  end
end

