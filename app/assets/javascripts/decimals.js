$(function() {
  Inputmask.extendAliases({
    'customDecimal': {
      alias: 'decimal',
      digits: 2,
      digitsOptional: false,
      groupSeparator: '.',
      radixPoint: ',',
      autoGroup: true,
      allowPlus: false,
      allowMinus: false,
      positionCaretOnTab: true,
      rightAlign: false
    }
  });

  $('input.decimal:not(.auto-inputmask-disabled)').inputmask('customDecimal');
});
