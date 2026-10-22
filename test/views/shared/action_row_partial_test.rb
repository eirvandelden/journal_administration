require "test_helper"

class SharedActionRowPartialTest < ActionView::TestCase
  def render_row(**locals)
    form = ActionView::Helpers::FormBuilder.new(:account, accounts(:checking), self, {})
    render partial: "shared/action_row", locals: { form: form, cancel_path: "/accounts/1" }.merge(locals)
    Nokogiri::HTML5.fragment(rendered)
  end

  test "renders Verwijderen…, Annuleren, Opslaan in that order" do
    footer = render_row(delete_form_id: "delete_account_1", confirm: "Sure?").at_css("footer")

    labels = footer.element_children.map { |node| node.text.strip.presence || node["value"] }

    assert_equal [ I18n.t("common.delete_ellipsis"), I18n.t("common.cancel"), I18n.t("common.save") ], labels
  end

  test "leaves Verwijderen… out without a delete form id" do
    footer = render_row.at_css("footer")

    labels = footer.element_children.map { |node| node.text.strip.presence || node["value"] }

    assert_equal [ I18n.t("common.cancel"), I18n.t("common.save") ], labels
  end

  test "Verwijderen… points at the delete form and carries the confirm" do
    button = render_row(delete_form_id: "delete_account_1", confirm: "Sure?").at_css("footer button")

    assert_equal "delete_account_1", button["form"]
    assert_equal "Sure?", button["data-turbo-confirm"]
    assert_includes button["class"], "button-danger"
  end

  test "Annuleren is a secondary link to the cancel path" do
    link = render_row.at_css("footer a")

    assert_equal "/accounts/1", link["href"]
    assert_equal "button", link["role"]
    assert_includes link["class"], "button-secondary"
  end
end
