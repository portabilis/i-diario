class TestSettingTestsController < ApplicationController
  respond_to :json

  def show
    @test_setting_test = TestSettingTest.find_by_id(params[:id])

    respond_with(@test_setting_test)
  end
end