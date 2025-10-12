require "application_system_test_case"

class ChattelsTest < ApplicationSystemTestCase
  setup do
    @chattel = chattels(:one)
  end

  test "visiting the index" do
    visit chattels_url
    assert_selector "h1", text: "Chattels"
  end

  test "should create chattel" do
    visit chattels_url
    click_on "New chattel"

    fill_in "Kind", with: @chattel.kind
    fill_in "Left posession at", with: @chattel.left_possession_at
    fill_in "Model number", with: @chattel.model_number
    fill_in "Name", with: @chattel.name
    fill_in "Notes", with: @chattel.notes
    fill_in "Purchase price", with: @chattel.purchase_price
    fill_in "Purchase transaction", with: @chattel.purchase_transaction_id
    fill_in "Purchased at", with: @chattel.purchased_at
    fill_in "Serial number", with: @chattel.serial_number
    fill_in "Warranty expires at", with: @chattel.warranty_expires_at
    click_on "Create Chattel"

    assert_text "Chattel was successfully created"
    click_on "Back"
  end

  test "should update Chattel" do
    visit chattel_url(@chattel)
    click_on "Edit this chattel", match: :first

    fill_in "Kind", with: @chattel.kind
    fill_in "Left posession at", with: @chattel.left_possession_at.to_s
    fill_in "Model number", with: @chattel.model_number
    fill_in "Name", with: @chattel.name
    fill_in "Notes", with: @chattel.notes
    fill_in "Purchase price", with: @chattel.purchase_price
    fill_in "Purchase transaction", with: @chattel.purchase_transaction_id
    fill_in "Purchased at", with: @chattel.purchased_at.to_s
    fill_in "Serial number", with: @chattel.serial_number
    fill_in "Warranty expires at", with: @chattel.warranty_expires_at.to_s
    click_on "Update Chattel"

    assert_text "Chattel was successfully updated"
    click_on "Back"
  end

  test "should destroy Chattel" do
    visit chattel_url(@chattel)
    click_on "Destroy this chattel", match: :first

    assert_text "Chattel was successfully destroyed"
  end
end
