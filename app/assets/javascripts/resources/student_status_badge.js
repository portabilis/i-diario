(function () {
  var STATUSES = {
    'active-search':            { label: 'Busca Ativa',   title: 'Aluno em busca ativa' },
    'dependence':               { label: 'Dependência',   title: 'Aluno cursando dependência' },
    'exempted':                 { label: 'Dispensado',    title: 'Aluno dispensado da avaliação' },
    'inactive':                 { label: 'Não enturmado', title: 'Aluno não enturmado' },
    'exempted-from-discipline': { label: 'Dispensado',    title: 'Aluno dispensado da disciplina' }
  };

  window.renderStudentStatusBadge = function (status) {
    var info = STATUSES[status];
    if (!info) return '';

    return '<span class="badge-status badge-status--' + status + '" title="' + info.title + '">' +
           info.label +
           '</span>';
  };
})();
