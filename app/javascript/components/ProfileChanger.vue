<template>
  <div>
    <a id="user-info-selector" href="#">
      <span>
        Alterar perfil
        <i class="fa fa-angle-right" aria-hidden="true"></i>
      </span>
    </a>

    <div id="current-role-selector">
      <form
        id="user-role-form"
        action="/current_role"
        method="post"
        >

        <input type="hidden" name="authenticity_token" v-model="x_csrf_token" />
        <input type="hidden" name="user[teacher_id]" v-model="teacher_id" />

        <b-current-role :any-component-loading="anyComponentLoading"></b-current-role>
        <b-current-unity :any-component-loading="anyComponentLoading"></b-current-unity>
        <b-current-school-year :any-component-loading="anyComponentLoading"></b-current-school-year>
        <b-current-classroom :any-component-loading="anyComponentLoading"></b-current-classroom>
        <b-current-teacher :any-component-loading="anyComponentLoading"></b-current-teacher>
        <b-current-discipline :any-component-loading="anyComponentLoading"></b-current-discipline>

        <div class="role-selector">
          <button :disabled="!validForm" class="btn btn-sm bg-color-blueDark txt-color-white">
            Alterar perfil
          </button>
          <a class="btn btn-sm bg-color-white txt-color-blueDark role-cancel">Cancelar</a>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import { EventBus  } from "../packs/event-bus.js"
import _ from "lodash"

import CurrentRole from './CurrentRole.vue'
import CurrentUnity from './CurrentUnity.vue'
import CurrentSchoolYear from './CurrentSchoolYear.vue'
import CurrentClassroom from './CurrentClassroom.vue'
import CurrentTeacher from './CurrentTeacher.vue'
import CurrentDiscipline from './CurrentDiscipline.vue'

export default {
  name: "b-profile-changer",
  data () {
    return {
      teacher_id: window.state.teacher_id,
      "x_csrf_token": document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
      isClassroomValid: false,
      isRoleValid: false,
      isSchoolYearValid: false,
      isTeacherValid: false,
      isDisciplineValid: false,
      isUnityValid: false,
      loading: {
        role: false,
        schoolYear: false,
        unity: false,
        classroom: false,
        taecher: false,
        discipline: false
      }
    }
  },
  computed: {
    validForm () {
      return this.isClassroomValid &&
        this.isRoleValid &&
        this.isSchoolYearValid &&
        this.isTeacherValid &&
        this.isDisciplineValid &&
        this.isUnityValid
    },
    anyComponentLoading () {
      return _.some(this.loading, (value) => {
        return value === true
      })
    }
  },
  methods: {
    isValid(data) {
      return data.selected != null || data.required
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
  created () {
    EventBus.$on("set-role", (roleData) => {
      this.isRoleValid = this.isValid(roleData)
      this.loading.role = roleData.isLoading
    })
    EventBus.$on("set-unity", (unityData) => {
      this.isUnityValid = this.isValid(unityData)
      this.loading.unity = unityData.isLoading
    })
    EventBus.$on("set-school-year", (schoolYearData) => {
      this.isSchoolYearValid = this.isValid(schoolYearData)
      this.loading.schoolYear = schoolYearData.isLoading
    })
    EventBus.$on("set-classroom", (classroomData) => {
      this.isClassroomValid = this.isValid(classroomData)
      this.loading.classroom = classroomData.isLoading
    })
    EventBus.$on("set-teacher", (teacherData) => {
      this.isTeacherValid = this.isValid(teacherData)
      this.loading.teacher = teacherData.isLoading
    })
    EventBus.$on("set-discipline", (disciplineData) => {
      this.isDisciplineValid = this.isValid(disciplineData)
      this.loading.discipline = disciplineData.isLoading
    })
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

#current-role-selector .required:after {
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
