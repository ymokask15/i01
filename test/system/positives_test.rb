require "application_system_test_case"

class PositivesTest < ApplicationSystemTestCase
  setup do
    @positive = positives(:one)
  end

  test "visiting the index" do
    visit positives_url
    assert_selector "h1", text: "Positives"
  end

  test "creating a Positive" do
    visit positives_url
    click_on "New Positive"

    fill_in "Count", with: @positive.count
    fill_in "Datetime", with: @positive.datetime
    fill_in "Place", with: @positive.place
    fill_in "Word", with: @positive.word
    click_on "Create Positive"

    assert_text "Positive was successfully created"
    click_on "Back"
  end

  test "updating a Positive" do
    visit positives_url
    click_on "Edit", match: :first

    fill_in "Count", with: @positive.count
    fill_in "Datetime", with: @positive.datetime
    fill_in "Place", with: @positive.place
    fill_in "Word", with: @positive.word
    click_on "Update Positive"

    assert_text "Positive was successfully updated"
    click_on "Back"
  end

  test "destroying a Positive" do
    visit positives_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Positive was successfully destroyed"
  end
end
