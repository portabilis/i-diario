function onChangeFileElement(){
  if (this.files[0].size > 3145728) {
    $(this).closest(".control-group").find('span').remove();
    $(this).closest(".control-group").addClass("error");
    $(this).after('<span class="help-inline">tamanho máximo por arquivo: 3 MB</span>');
    $(this).val("");
  }else {
    $(this).closest(".control-group").removeClass("error");
    $(this).closest(".control-group").find('span').remove();
  }
}

function validate_attachment_size(element){
  element.on('cocoon:after-insert', function(e, item) {
    $(item).find('input.file').on('change', onChangeFileElement);
  });
}
