$(function() {
  var $returnReasonContainer = $("[data-material-exit-return-reason]"),
      $requestAuthorizationContainer = $("[data-material-exit-request-authorization]"),
      $destinationUnityContainer = $("[data-material-exit-destination-unity]"),
      $materialItemsContainer = $("#material-exits-items"),
      $supplierContainer = $("[data-material-exit-supplier]"),
      $supplier = $("#material_exit_supplier_id"),
      $returnReason = $("#material_exit_return_reason"),
      $kind = $("#material_exit_kind"),
      $requestAuthorization = $("#material_exit_material_request_authorization_id"),
      $destinationUnity = $("#material_exit_destination_unity_id"),
      itemTemplate = $("#material_exit_items a.add_fields").attr("data-association-insertion-template"),
      $***REMOVED*** = [],
      $unities = [],
      $unity_id = 0,
      $measuring_unit_id = 0;
      flashMessages = new FlashMessages(),

  toggleReturnReason($kind.val() === 'return');
  toggleRequestAuthorization($kind.val() === 'transfer');
  toggleDestinationUnity($kind.val() != '' && $kind.val() !== 'consumption');
  toggle***REMOVED***($kind.val() != '' && $kind.val() !== 'consumption');
  alterUnit();

  $kind.on('change', function(e) {
    toggleReturnReason(e.val === 'return');
    toggleRequestAuthorization(e.val === 'transfer');
    toggleDestinationUnity(e.val !== 'consumption');
    toggle***REMOVED***(e.val !== 'consumption');
  });

  $requestAuthorization.on('change', function(e) {
    fetchAuthorizationItems(e.val);
    fetchMaterailRequestAuthorizations($requestAuthorization.val());
  });

  $('#material-exits-items').on('cocoon:after-insert', function() {
    $("[id$=material_id]").on("change", function(){
      alterUnit();
    });
  });

  function select***REMOVED***Id(items){
    _.each(items, function(item) {
      if(item['id'] == $material_id){
        $measuring_unit_id = item['measuring_unit_id'];
      }
    });
  }

  function selectUnit(items){
    var unit;
    _.each(items, function(item) {
      if(item['id'] == $measuring_unit_id){
        unit = item['symbol'];
      }
    });
    if($material_id == 'empty'){
      return '';
    }else{
      return unit;
    }
  }

  function alterUnit(){
    $material_id = $("input[id$=material_id]").val();
      
    $.ajax({
      type: "GET",
      url: "/***REMOVED***/json",
      success: select***REMOVED***Id        
    });

    $.ajax({
      type: "GET",
      url: "/***REMOVED***/json",
      success: function(items){ 
        $("span.measuring-unit").html(selectUnit(items));
      }       
    });
  }
  
  function fetchAuthorizationItems(authorizationId) {
    $.ajax({
      url: '/autorizacoes-de-requisicoes-de-materiais/' + authorizationId +
        '/items-de-autorizacoes-de-requisicoes-de-materiais.json',
      success: renderAuthorizationItems,
      error: handleError
    });
  }


  function fetchMaterailRequestAuthorizations(materialRequestAuthorization) {
    loading***REMOVED***Request();
    loadUnities();
    $.ajax({
      type: "GET",
      url: "/***REMOVED***/json",
      success: function(items){
      var material_request_id; 
        var selectedDestinationUnity = [];
        _.each(items, function(item){
          if(materialRequestAuthorization == item['id']){
            material_request_id = item['material_request_id'];
          }
        });
        _.each($***REMOVED***, function(item){
          if(material_request_id == item['id']){
            $unity_id = item['origin_unity_id'];
          }
        });
        _.each($unities, function(item){
          if($unity_id == item['id']){
            selectedDestinationUnity.push({id: item['id'], text: item['name'] });
          }
        });
        setTimeout(alterInputUnityDestination(selectedDestinationUnity), 500);
      }
    });
  }

  function alterInputUnityDestination(destination){
    $destinationUnity.select2({
      data: destination
    });
    $destinationUnity.select2('val', $unity_id );
  }

  function loading***REMOVED***Request(){
    $.ajax({
      type: "GET",
      url: "/***REMOVED***/json",
      success: return***REMOVED***Requests
    });
  }

  function loadUnities(){
    $.ajax({
      type: "GET",
      url: "/unities/json",
      success: returnUnities
    });
  }
  
  function returnUnities(items){
    $unities = items;
  }

  function return***REMOVED***Requests(items){
    $***REMOVED*** = items;
  }

  function renderAuthorizationItems(items) {
    var output = [];

    $materialItemsContainer.hide();
    $materialItemsContainer.find("a.remove_fields").trigger("click");

    _.each(items, function(item) {
      item.quantity = parseFloat(item.quantity).toFixed(2);
      output.push(updateTemplate(item));
    });

    $materialItemsContainer.append(output);
    $('form').trigger('cocoon:after-insert');
    $materialItemsContainer.show();
  }

  function handleError() {
    flashMessages.error('Problemas ao buscar items da autorização.');
  }

  function updateTemplate(item) {
    var output = $(itemTemplate.replace(/new_items/g, new Date().getTime()));

    output.find("[id$=quantity]").val(item.quantity);
    output.find("[id$=material_id]").val(item.material.id);
    output.find("span.measuring-unit").html(item.material.measuring_unit);

    return output;
  }


  function toggleReturnReason(show) {
    if (show) {
      $returnReasonContainer.show();
    } else {
      $returnReasonContainer.hide();
      $returnReason.val('');
    }
  }

  function toggle***REMOVED***(show) {
    if (show) {
      $supplierContainer.show();
    } else {
      $supplierContainer.hide();
      $supplier.select2('val','');
    }
  }

  function toggleRequestAuthorization(show) {
    if (show) {
      $requestAuthorizationContainer.show();
    } else {
      $destinationUnity.prop('disabled', false)
      $requestAuthorization.select2('val', '');
    }
  }

  function toggleDestinationUnity(show) {

    if (show) {
      $destinationUnityContainer.show();
    } else {
      $destinationUnityContainer.hide();
      $destinationUnity.select2('val', '');
    }
  }
});
