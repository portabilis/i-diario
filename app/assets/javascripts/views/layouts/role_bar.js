$(function() {
  'use strict';

  function markRequired(selector) {
    $(selector).css('color', '#b94a48');
  }

  function markSelected(selector) {
    $(selector).css('color', '');
  }

  function clearActive(elm) {
    elm
      .closest('ul')
      .find('li.active')
      .removeClass('active');
  }

  function setActiveText(name, selector) {
    if (!name.startsWith('Sem ')) {
      name = name + ' <i class="fa fa-angle-down"></i>';
    }

    $('.project-selector' + selector).html(name);
  }

  function setActiveOptions(selector, data, id) {
    var activeOptions = $(selector).map(function() {
      var elm = $(this).removeClass('active');
      if (elm.data(data).includes(id)) {
        elm.show();
        return true;
      } else {
        elm.hide();
      }
    });

    return activeOptions.length > 0;
  }

  // $('.dropdown-***REMOVED***.user-roles a[data-user-role]').on('click', function(e) {
  //   e.preventDefault();

  //   var elm = $(this);
  //   clearActive(elm);

  //   setActiveText(
  //     elm
  //       .parent()
  //       .addClass('active')
  //       .text(),
  //     '.user-role'
  //   );

  //   var accessLevel = elm.data('access-level');
  //   $('.project-context').hide();
  //   $('.project-context.' + accessLevel).show();
  // });

  $('.dropdown-***REMOVED***.user-roles a[data-user-role]').on('click', function(e) {
    e.preventDefault();

    var elm = $(this);
    clearActive(elm);

    setActiveText(
      elm
        .parent()
        .addClass('active')
        .text(),
      '.user-role'
    );

    $('#user_current_user_role_id').val(elm.data('user-role'));

    var accessLevel = elm.data('access-level');
    $('.project-context').hide();
    $('.project-context.' + accessLevel).show();

    $('#user-role-form input').removeAttr('required');
    $('#user-role-form input.' + accessLevel).attr('required', true);

    // console.log(unityId);
    // if (unityId > 0) {
    //   $('#user_current_unity_id').val(unityId);
    //   setActiveOptions(
    //     '.dropdown-***REMOVED***.teachers li[data-unities]',
    //     'unities',
    //     unityId
    //   );
    //   $('#user-role-form input.teacher').attr('required', true);
    // }

    if (accessLevel == 'teacher') {
      $('.dropdown-***REMOVED***.classrooms [data-unity]').hide();

      var unityId = elm.data('unity');
      var classrooms = $(
        '.dropdown-***REMOVED***.classrooms [data-unity=' + unityId + ']'
      );

      if (classrooms.length === 0) {
        setActiveText('Sem turma', '.classroom');
        setActiveText('Sem disciplina', '.discipline');

        $('.dropdown-***REMOVED***.classrooms').hide();
      } else {
        $('.dropdown-***REMOVED***.classrooms').removeAttr('style');

        setActiveText('Selecione', '.classroom');
        setActiveText('Selecione', '.discipline');

        setActiveOptions(
          '.dropdown-***REMOVED***.classrooms li[data-unity=' +
            unityId +
            '][data-teachers]',
          'teachers',
          parseInt($('#user_teacher_id').val(), 10)
        );
      }
    }
  });

  $('.dropdown-***REMOVED***.unities a[data-unity]').on('click', function(e) {
    e.preventDefault();

    var elm = $(this);
    clearActive(elm);

    setActiveText(
      elm
        .parent()
        .addClass('active')
        .text(),
      '.unity'
    );

    $('#user_current_unity_id').val(elm.data('unity'));

    var hasActiveOptions = setActiveOptions(
      '.dropdown-***REMOVED***.teachers li[data-unities]',
      'unities',
      elm.data('unity')
    );
    if (hasActiveOptions) {
      setActiveText('Selecione', '.teacher');
      setActiveText('Selecione', '.classroom');
      setActiveText('Selecione', '.discipline');

      $('.dropdown-***REMOVED***.teachers').removeAttr('style');
    } else {
      setActiveText('Sem professor', '.teacher');
      setActiveText('Sem turma', '.classroom');
      setActiveText('Sem disciplina', '.discipline');

      $('.dropdown-***REMOVED***.teachers').hide();
    }
  });

  $('.dropdown-***REMOVED***.teachers a[data-teacher]').on('click', function(e) {
    e.preventDefault();

    var elm = $(this);
    clearActive(elm);

    setActiveText(
      elm
        .parent()
        .addClass('active')
        .text(),
      '.teacher'
    );

    $('#user_teacher_id').val(elm.data('teacher'));

    var hasActiveOptions = setActiveOptions(
      '.dropdown-***REMOVED***.classrooms li[data-teachers]',
      'teachers',
      elm.data('teacher')
    );
    if (hasActiveOptions) {
      setActiveText('Selecione', '.classroom');
      setActiveText('Selecione', '.discipline');

      $('.dropdown-***REMOVED***.classrooms').removeAttr('style');
    } else {
      setActiveText('Sem turma', '.classroom');
      setActiveText('Sem disciplina', '.discipline');

      $('.dropdown-***REMOVED***.classrooms').hide();
    }

    $('#user-role-form input.teacher').attr('required', true);
  });

  $('.dropdown-***REMOVED***.classrooms a[data-classroom]').on('click', function(e) {
    e.preventDefault();

    var elm = $(this);
    clearActive(elm);

    setActiveText(
      elm
        .parent()
        .addClass('active')
        .text(),
      '.classroom'
    );

    $('#user_current_classroom_id').val(elm.data('classroom'));
    markSelected('.project-context .project-selector.classroom');

    var hasActiveOptions = setActiveOptions(
      '.dropdown-***REMOVED***.disciplines li[data-classrooms]',
      'classrooms',
      elm.data('classroom')
    );
    if (hasActiveOptions) {
      setActiveText('Selecione', '.discipline');

      $('.dropdown-***REMOVED***.disciplines').removeAttr('style');
    } else {
      setActiveText('Sem disciplina', '.discipline');

      $('.dropdown-***REMOVED***.disciplines').hide();
    }
  });

  $('.dropdown-***REMOVED***.disciplines li a').on('click', function(e) {
    e.preventDefault();

    var elm = $(this);
    clearActive(elm);

    setActiveText(
      elm
        .parent()
        .addClass('active')
        .text(),
      '.discipline'
    );

    $('#user_current_classroom_id').val(elm.data('discipline'));
  });

  $('#user-role-form').on('ajax:success', location.reload.bind(location));

  $('.select-role').on('click', function(e) {
    e.preventDefault();

    var emptyFields = $('#user-role-form input[required]').map(function() {
      var elm = $(this);
      if ($.trim(elm.val()) === '') {
        var dropdown = elm.data('dropdown');
        if (dropdown) {
          markRequired(dropdown);
        }
        return true;
      }
    });

    console.log(emptyFields);
    if (emptyFields.length === 0) {
      $('#user-role-form').submit();
    }

    // var url = $(this).data('url');
    // var params = {
    //   current_user_role_id: null,
    //   current_unity_id: null,
    //   assumed_teacher_id: null,
    //   current_classroom_id: null,
    //   current_discipline_id: null,
    //   current_user_role_id: null
    // };

    // $.ajax({
    //   type: 'PATCH',
    //   url: url,
    //   data: { user: params },
    //   success: location.reload.bind()
    // });
  });
});
