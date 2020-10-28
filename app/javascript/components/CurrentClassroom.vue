<template>
  <div id="current-classroom-container"
       class="project-context"
       v-if="displayable">
    <span :class="{ required, label: true }">
      Turma
    </span>

    <input type="hidden" name="user[current_classroom_id]" v-model="selected.id" v-if="selected" />
    <multiselect v-model="selected"
                 :options="options"
                 :searchable="true"
                 :close-on-select="true"
                 :placeholder="isLoading ? 'Carregando...' : 'Selecione'"
                 :allow-empty="false"
                 :loading="isLoading"
                 :disabled="anyComponentLoading"
                 @input="classroomHasBeenSelected(selected, true)"
                 track-by="id"
                 label="description"
                 deselect-label=""
                 select-label=""
                 selected-label="">
      <span slot="noResult">Não encontrado...</span>
      <span slot="noOptions">Não há turmas...</span>
    </multiselect>
  </div>
</template>

<script>
import axios from 'axios'
import { EventBus  } from "../packs/event-bus.js"

export default {
  name: "b-current-classroom",
  props: [ 'anyComponentLoading', 'byTeacherProfile' ],
  data() {
    return {
      defaultOptions: window.state.available_classrooms,
      options: [],
      rawOptions: [],
      selected: window.state.current_classroom,
      isLoading: false,
      role: null,
      unity: null,
      schoolYear: null,
      required: false
    }
  },
  computed: {
    displayable () {
      return (this.isLoading || this.rawOptions.length) && this.schoolYear && !this.byTeacherProfile
    },
    route() {
      let filters = {
        by_unity_id: this.unity.id,
        by_school_year: this.schoolYear.id,
        by_user_role_id: this.role.id
      }

      if (this.role.role_access_level === 'teacher') {
        filters['by_teacher_id'] = window.state.teacher_id
      }

      return Routes.available_classrooms_pt_br_path({ filter: filters, format: 'json' })
    }
  },
  methods: {
    setOptions(classrooms) {
      this.rawOptions = classrooms

      if (this.role && this.role.role_access_level !== 'teacher') {
        this.options = [{}].concat(classrooms)
      } else {
        this.options = classrooms
      }
    },
    classroomHasBeenSelected(classroom, toFetch = true) {
      EventBus.$emit("set-classroom", this.$data);

      if(toFetch) {
        EventBus.$emit("fetch-teachers", this.selected);
      }
    }
  },
  mounted () {
    this.setOptions(window.state.available_classrooms)
    this.classroomHasBeenSelected(this.selected, false)
  },
  created () {
    EventBus.$on("set-role", (roleData) => {
      this.role = roleData.selected
      this.required = this.role && this.role.role_access_level === 'teacher'
    })

    EventBus.$on("set-unity", (unityData) => {
      this.unity = unityData.selected
    })

    EventBus.$on("set-school-year", (schoolYearData) => {
      this.schoolYear = schoolYearData.selected
    })

    EventBus.$on("fetch-classrooms", async (schoolYear) => {
      this.isLoading = true
      this.selected = null
      this.setOptions([])

      this.classroomHasBeenSelected(this.selected)

      if (schoolYear) {
        await axios
          .get(this.route)
          .then(({ data }) => {
            const classrooms = data.classrooms

            this.setOptions(classrooms)

            if(classrooms.length === 1) {
              this.selected = classrooms[0]
            }
          })
      }

      this.isLoading = false
      this.classroomHasBeenSelected(this.selected)
    })
  }
}
</script>

<style>
#current-classroom-container {
  width: 150px;
}
@media (max-width: 1365px) {
  #current-classroom-container {
    width: 100%;
  }
}
</style>
