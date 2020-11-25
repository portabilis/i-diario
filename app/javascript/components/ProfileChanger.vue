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

        <b-current-role :by-teacher-profile="byTeacherProfile"
                        :any-component-loading="anyComponentLoading"></b-current-role>

        <b-current-unity :by-teacher-profile="byTeacherProfile"
                         :any-component-loading="anyComponentLoading"></b-current-unity>

        <b-current-school-year :by-teacher-profile="byTeacherProfile"
                               :any-component-loading="anyComponentLoading"></b-current-school-year>

        <b-current-classroom :by-teacher-profile="byTeacherProfile"
                             :any-component-loading="anyComponentLoading"></b-current-classroom>

        <b-current-teacher :by-teacher-profile="byTeacherProfile"
                           :any-component-loading="anyComponentLoading"></b-current-teacher>

        <b-current-discipline :by-teacher-profile="byTeacherProfile"
                              :any-component-loading="anyComponentLoading"></b-current-discipline>

        <b-teacher-profile :by-teacher-profile="byTeacherProfile"
                           :any-component-loading="anyComponentLoading"></b-teacher-profile>

        <div class="role-selector">
          <button v-show="this.submitAble()" :disabled="!validForm" class="btn btn-sm bg-color-blueDark txt-color-white" data-disable-with='Alterando...'>
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
import TeacherProfile from './TeacherProfile.vue'

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
      isTeacherProfileValid: false,
      profiles: window.state.profiles,
      loading: {
        role: false,
        schoolYear: false,
        unity: false,
        classroom: false,
        taecher: false,
        discipline: false,
        profile: false
      },
      role: null,
      roles: null
    }
  },
  computed: {
    validForm () {
      if (this.isStudentOrParent) {
        return true
      } else if (this.byTeacherProfile) {
        return this.isRoleValid &&
          this.isSchoolYearValid &&
          this.isUnityValid &&
          this.isTeacherProfileValid
      } else {
        return this.isClassroomValid &&
          this.isRoleValid &&
          this.isSchoolYearValid &&
          this.isTeacherValid &&
          this.isDisciplineValid &&
          this.isUnityValid
      }
    },
    anyComponentLoading () {
      return _.some(this.loading, (value) => {
        return value === true
      })
    },
    byTeacherProfile () {
      return this.profiles && this.profiles.length > 0 && this.profiles.length <= 15
    },
    isStudentOrParent () {
      return this.role && (this.role.role_access_level === "student" || this.role.role_access_level === "parent")
    }
  },
  methods: {
    isValid (data) {
      return !!data && (!data.required || !!data.selected)
    },
    submitAble () {
      if (this.isStudentOrParent) {
        return this.roles.length > 1
      }

      return true
    }
  },
  components: {
    'b-current-role': CurrentRole,
    'b-current-unity': CurrentUnity,
    'b-current-school-year': CurrentSchoolYear,
    'b-current-classroom': CurrentClassroom,
    'b-current-teacher': CurrentTeacher,
    'b-current-discipline': CurrentDiscipline,
    'b-teacher-profile': TeacherProfile
  },
  created () {
    EventBus.$on("set-role", (roleData) => {
      this.isRoleValid = this.isValid(roleData)
      this.loading.role = roleData.isLoading
      this.role = roleData.selected
      this.roles = roleData.options
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
    EventBus.$on("set-teacher-profile", (profileData) => {
      this.isTeacherProfileValid = this.isValid(profileData)
      this.loading.profile = profileData.isLoading
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
