<template>
  <div id="profile-changer-container">
    <form
      id="profile-changer"
      @submit="checkForm"
      action="/current_role"
      method="post"
      >

      <input type="hidden" name="authenticity_token" v-model="x_csrf_token" />
      <input type="hidden" name="user[teacher_id]" v-model="teacher_id" />

      <b-current-role></b-current-role>
      <br>
      <b-current-unity></b-current-unity>
      <br>
      <b-current-school-year></b-current-school-year>
      <br>
      <b-current-classroom></b-current-classroom>
      <br>
      <b-current-teacher></b-current-teacher>
      <br>
      <b-current-discipline></b-current-discipline>
      <br>
      <button :disabled="!validForm">
        Alterar perfil
      </button>
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
  methods: {
    checkForm () {

    }
  }
}
</script>
