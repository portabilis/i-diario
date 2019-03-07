$(function() {
  $('form').on('cocoon:after-insert', function(){
    var $lastTr = $('tbody#user-roles tr:last');
    var idSplitted = $lastTr.find('[id*="_id"]').last().attr('id').split('_');
    var uniqueId = idSplitted[idSplitted.length-2];    

    $('tbody#user-roles tr:last').find('[name*="cocoonReplaceUniqueId"]').each(function(){
      $(this).attr('name', $(this).attr('name').replace('cocoonReplaceUniqueId', uniqueId));
    });

    $('tbody#user-roles tr:last').find('[id*="cocoonReplaceUniqueId"]').each(function(){
      $(this).attr('id', $(this).attr('id').replace('cocoonReplaceUniqueId', uniqueId));
    });

    createSelect2Remote(true, 'tbody#user-roles tr:last input.select2_remote', '');
  });
});
