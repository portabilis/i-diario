$(function() {
  var $calculationType = $('#complementary_exam_setting_calculation_type');

  var toggleCalculationTypeInfo = function(calculation_type){
    hideAllCalculationTypeInfo();
    var calculationTypeElementId = calculation_type + '-calculation-type-info';
    var $calculationTypeElement = $('#' + calculationTypeElementId);
    $calculationTypeElement.removeClass('hidden');
  }

  var hideAllCalculationTypeInfo = function (){
    $(".calculation-type-info").each(function(){
      $(this).addClass('hidden');
    });
  }

  $calculationType.on('change', function() {
    toggleCalculationTypeInfo($calculationType.select2("val"));
  });

  toggleCalculationTypeInfo($calculationType.select2("val"));
});
