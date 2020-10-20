<template>
  <div id="current-teacher-container"
       class="project-context"
       v-show="classroom && classroom.id && isAdminOrEmployee">
    <span :class="{ required, label: true  }">
      Professor
    </span>

    <input type="hidden" name="user[current_teacher_id]" v-model="selected.id" v-if="selected" />
    <multiselect v-model="selected"
                 :options="options"
                 :searchable="true"
                 :close-on-select="true"
                 :placeholder="isLoading ? 'Carregando...' : 'Selecione'"
                 :allow-empty="false"
                 :loading="isLoading"
                 :disabled="anyComponentLoading"
                 @input="teacherHasBeenSelected(selected, true)"
                 track-by="id"
                 label="name"
                 deselect-label=""
                 select-label=""
                 selected-label="">
      <span slot="noResult">Não encontrado...</span>
      <span slot="noOptions">Não há professores...</span>
    </multiselect>
  </div>
</template>

<script>
import axios from 'axios'
import _ from 'lodash'
import { EventBus  } from "../packs/event-bus.js"

export default {
  name: "b-current-teacher",
  props: [ 'anyComponentLoading' ],
  data() {
    return {
      options: window.state.available_teachers,
      selected: window.state.current_teacher,
      isLoading: false,
      role: null,
      unity: null,
      school_year: null,
      classroom: null,
      required: false
    }
  },
  computed: {
    isAdminOrEmployee() {
      return this.role && (this.role.role_access_level === 'employee' || this.role.role_access_level === 'administrator')
    }
  },
  methods: {
    setRequired() {
      if (this.classroom && _.isEmpty(this.classroom)) {
        this.required = false
        return
      }

      this.required = this.role &&
        this.role.role_access_level !== 'parent' &&
        this.role.role_access_level !== 'student'
    },
    route(classroom) {
      const filters = {
        by_unity_id: this.unity.id,
        by_school_year: this.school_year.id,
        by_classroom_id: classroom.id,
        by_user_role_id: this.role.id
      }

      return Routes.available_teachers_pt_br_path({
        filter: filters,
        format: 'json'
      })
    },
    teacherHasBeenSelected(teacher, toFetch = true) {
      EventBus.$emit("set-teacher", this.$data);

      if(toFetch) {
        EventBus.$emit("fetch-disciplines", teacher);
      }
    }
  },
  mounted () {
    this.teacherHasBeenSelected(this.selected, false)
  },
  created: function () {
    EventBus.$on("set-role", (roleData) => {
      this.role = roleData.selected
      this.setRequired()
    })

    EventBus.$on("set-school-year", (schoolYearData) => {
      this.school_year = schoolYearData.selected
    })

    EventBus.$on("set-unity", (unityData) => {
      this.unity = unityData.selected
    })

    EventBus.$on("set-classroom", (classroomData) => {
      this.classroom = classroomData.selected
      this.setRequired()
    })

    EventBus.$on("fetch-teachers", async (classroom) => {
      this.isLoading = true
      this.selected = null
      this.options = []

      this.teacherHasBeenSelected(this.selected)

      if (classroom) {
        await axios.get(this.route(classroom))
          .then(({ data }) => {
            this.options = data.teachers

            if(this.options.length === 1) {
              this.selected = this.options[0]
            }
          })
      }

      this.isLoading = false
      this.teacherHasBeenSelected(this.selected)
    })
  }
}
</script>

<style>
#current-teacher-container {
  width: 150px;
}
@media (max-width: 1365px) {
  #current-teacher-container {
    width: 100%;
  }
}
</style>
