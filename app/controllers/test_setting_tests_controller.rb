class TestSettingTestsController < ApplicationController
  respond_to :json

  def index
    @test_setting_tests = TestSettingTest.where(test_setting_id: params[:test_setting_id])

    render json: @test_setting_tests
  end

  def show
    @test_setting_test = TestSettingTest.find_by_id(params[:id])

    respond_with(@test_setting_test)
  end
end