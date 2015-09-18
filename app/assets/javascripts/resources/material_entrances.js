$(function() {
  var $supplier = $("[data-material-entrance-supplier]"),
      $materialExitFields = $("[data-material-entrance-material-exit]"),
      $materialItems = $("#material-entrance-items"),
      $materialItem = $("#material_entrance_items_material_id"),
      $kind = $("#material_entrance_kind"),
      $materialExit = $("#material_entrance_material_exit_id"),
      itemTemplate = $("#material_entrance_items a.add_fields").attr("data-association-insertion-template"),
      flashMessages = new FlashMessages(),
      $materialItemsTotalValue = $('#entrance-material-items-total-value'),
      $measuring_unit_id = 0;

  toggle***REMOVED***($kind.val() === 'supplier');
  toggle***REMOVED***();
  update***REMOVED***Unit();
  alterUnit();
  
  $kind.on('change', function(e) {
    toggle***REMOVED***(e.val === 'supplier');
    toggle***REMOVED***();
  });

  $materialExit.on('change', function(e) {
    fetchExitItems(e.val);
  });

  function fetchExitItems(exitId) {
    $.ajax({
      url: '/saidas-de-materiais/' + exitId + '/items-de-saidas-de-materiais.json',
      success: renderExitItems,
      error: handleError
    });
  }

  function renderExitItems(items) {
    var output = [];

    $materialItems.hide();
    $materialItems.find("a.remove_fields").trigger("click");

    _.each(items, function(item) {
      item.quantity = parseFloat(item.quantity).toFixed(2);
      output.push(updateTemplate(item));
    });

    $materialItems.append(output);
    $('form').trigger('cocoon:after-insert');
    $materialItems.show();
    toggle***REMOVED***($kind.val() === 'supplier');
  }

  $('#material_entrance_items').on('cocoon:after-insert', function(e, item) {
    toggle***REMOVED***($kind.val() === 'supplier');
    
    $("[id$=unit_value], [id$=quantity]").on("blur", update***REMOVED***Totals);
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
  
  $('#material_entrance_items').on('cocoon:after-remove', function(e, item) {
    update***REMOVED***Totals();
  })

  function updateTemplate(item) {
    var output = [];

    output = $(itemTemplate.replace(/new_items/g, new Date().getTime()));

    output.find("[id$=quantity]").val(item.quantity);
    output.find("[id$=unit_value]").val(0);
    output.find("[id$=material_id]").val(item.material.id);
    output.find("span.measuring-unit").html(item.material.measuring_unit);
    return output;
  }

  function handleError() {
    flashMessages.error('Problemas ao buscar items da saída.');
  }

  function toggle***REMOVED***(show) {
    if (show) {
      $('.show-only-for-supplier').show();
      $supplier.show();
    } else {
      $('.show-only-for-supplier').hide();
      $("[id$=unit_value]").val('');
      $supplier.hide().find("input").val("");
      $supplier.find("input.select2").select2("val", "");
    }
  }

  function toggle***REMOVED***() {
    if($kind.val() === 'return'){
      $("label[for='material_entrance_material_exit_id']").text("Devolução");
      $materialExitFields.show();
    }else if($kind.val() === 'transfer'){
      $("label[for='material_entrance_material_exit_id']").text("Transferência");
      $materialExitFields.show();
    }else {
      $materialExitFields.hide().
        find("input.select2").select2("val", "");
    }
  }

  function update***REMOVED***Unit(){
    $materialItems.find('tr:visible'), function(i, row){
      var unit = $(row).find("[id$=unit_value]").val();
      var material = $(row).find("[id$=material_id]").val();
    }
  }

  var update***REMOVED***Totals = function(){
    var total_value = 0;
    $.each($materialItems.find('tr:visible'), function(i, row){
      var unit_value = $(row).find("[id$=unit_value]").val();
      var quantity = $(row).find("[id$=quantity]").val();
      var _total_value = unit_value.currencyToNumber() * quantity.currencyToNumber();
      total_value += _total_value;
      $(row).find('span.total-value').text("R$ "+_total_value.toCurrency());
    });

    $materialItemsTotalValue.text(total_value.toCurrency());
  }
  $("[id$=unit_value], [id$=quantity]").on("blur", update***REMOVED***Totals);
  update***REMOVED***Totals();
});
