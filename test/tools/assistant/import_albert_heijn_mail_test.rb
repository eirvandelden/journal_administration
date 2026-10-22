require "test_helper"

class Assistant::ImportAlbertHeijnMailTest < ActiveSupport::TestCase
  test "answers the receipt, its source and the products still to classify" do
    response = import("albert_heijn_packing_slip.txt")

    assert_not response.error?
    assert_match(/order 100000001 delivered on 2026-08-28, 37 lines, packed/, text(response))
    assert_match(/Unclassified products: \d+/, text(response))
  end

  test "says when a packed basket was kept over an order confirmation" do
    import("albert_heijn_packing_slip.txt")
    confirmation = file_fixture("albert_heijn_order_confirmation.txt").read.sub("100000003", "100000001")

    response = Assistant::ImportAlbertHeijnMail.call(mail: confirmation, server_context: nil)

    assert_includes text(response), "Kept the packed basket"
  end

  test "refuses a mail it cannot read" do
    response = Assistant::ImportAlbertHeijnMail.call(mail: "Hallo", server_context: nil)

    assert_predicate response, :error?
    assert_includes text(response), "nothing was saved"
  end

  test "refuses a delivery before the first month in scope" do
    mail = file_fixture("albert_heijn_older_packing_slip.txt").read.sub("1 september 2023", "4 oktober 2022")

    response = Assistant::ImportAlbertHeijnMail.call(mail: mail, server_context: nil)

    assert_predicate response, :error?
    assert_includes text(response), "before 2022-11-01"
  end

  private

  def import(fixture)
    Assistant::ImportAlbertHeijnMail.call(mail: file_fixture(fixture).read, server_context: nil)
  end

  def text(response) = response.content.first[:text]
end
