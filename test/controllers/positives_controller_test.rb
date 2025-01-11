require 'test_helper'

class PositivesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @positive = positives(:one)
  end

  test "should get index" do
    get positives_url
    assert_response :success
  end

  test "should get new" do
    get new_positive_url
    assert_response :success
  end

  test "should create positive" do
    assert_difference('Positive.count') do
      post positives_url, params: { positive: { count: @positive.count, datetime: @positive.datetime, place: @positive.place, word: @positive.word } }
    end

    assert_redirected_to positive_url(Positive.last)
  end

  test "should show positive" do
    get positive_url(@positive)
    assert_response :success
  end

  test "should get edit" do
    get edit_positive_url(@positive)
    assert_response :success
  end

  test "should update positive" do
    patch positive_url(@positive), params: { positive: { count: @positive.count, datetime: @positive.datetime, place: @positive.place, word: @positive.word } }
    assert_redirected_to positive_url(@positive)
  end

  test "should destroy positive" do
    assert_difference('Positive.count', -1) do
      delete positive_url(@positive)
    end

    assert_redirected_to positives_url
  end
end
