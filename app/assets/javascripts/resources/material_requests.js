$(function() {
  $("fieldset#items a.add_fields").
    data("association-insertion-method", 'append').
    data("association-insertion-traversal", 'closest').
    data("association-insertion-node", 'fieldset#items');
 });
