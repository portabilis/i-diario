<template>
  <div id="profiler-changer">
    <form
      id="user-role-form"
      action="/current_role"
      method="post"
      >

      <input type="hidden" name="authenticity_token" v-model="x_csrf_token" />
      <input type="hidden" name="user[teacher_id]" v-model="teacher_id" />

      <b-current-role></b-current-role>
      <b-current-unity></b-current-unity>
      <b-current-school-year></b-current-school-year>
      <b-current-classroom></b-current-classroom>
      <b-current-teacher></b-current-teacher>
      <b-current-discipline></b-current-discipline>

      <div class="role-selector">
        <button :disabled="!validForm" class="btn btn-sm bg-color-blueDark txt-color-white">
          Alterar perfil
        </button>
        <a class="btn btn-sm bg-color-white txt-color-blueDark role-cancel">Cancelar</a>
      </div>
    </form>
  </div>
</template>

<script>
import CurrentRole from './CurrentRole.vue'
import CurrentUnity from './CurrentUnity.vue'
import CurrentSchoolYear from './CurrentSchoolYear.vue'
import CurrentClassroom from './CurrentClassroom.vue'
import CurrentTeacher from './CurrentTeacher.vue'
import CurrentDiscipline from './CurrentDiscipline.vue'

const containers = [
  '#current-unity-container',
  '#current-classroom-container',
  '#current-discipline-container',
  '#current-role-container',
  '#current-school-year-container',
  '#current-teacher-container'
]

export default {
  name: "b-profile-changer",
  data: function () {
    return {
      teacher_id: window.state.teacher_id,
      "x_csrf_token": document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    }
  },
  computed: {
    validForm () {
      return this.$store.state.isValid
    }
  },
  components: {
    'b-current-role': CurrentRole,
    'b-current-unity': CurrentUnity,
    'b-current-school-year': CurrentSchoolYear,
    'b-current-classroom': CurrentClassroom,
    'b-current-teacher': CurrentTeacher,
    'b-current-discipline': CurrentDiscipline
  },
  mounted() {
    this.$store.dispatch('setRequired')
  }
}
</script>

<style>
.multiselect, .multiselect__tags {
  font-size: 12px;
}

.multiselect__tags {
  height: 30px;
  min-height: 30px;
  padding: 4px 30px 0 4px;
  overflow: hidden;
}

.multiselect__single {
  font-size: 12px;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis '';
}
.multiselect__option {
  white-space: normal
}

.role-selector {
  display: inline-block;
  vertical-align: top;
  margin-top: 27px;
}

.multiselect__select {
  height: 30px;
  width: 30px;
}

.required:after {
  content:" *";
  color: #953b39;
}

.multiselect__option:hover,
.multiselect__option--highlight,
.multiselect__option--selected.multiselect__option--highlight {
  background-color: #3276b1
}

.multiselect__spinner {
  position: absolute;
  right: 2px;
  top: 2px;
  width: 25px;
  height: 25px;
}

.multiselect--disabled {
  background: none;
  opacity: 1;
}
.multiselect--disabled .multiselect__select {
  background: none;
}
</style>
