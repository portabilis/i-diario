<template>
  <div id="current-classroom-container"
       class="project-context"
       v-if="!byTeacherProfile && (isLoading || options.length)">
    <span :class="{ required, label: true  }">
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
  props: [ 'anyComponentLoading' ],
  data() {
    return {
      options: window.state.available_classrooms,
      selected: window.state.current_classroom,
      byTeacherProfile: window.state.profiles.length > 0,
      isLoading: false,
      role: null,
      unity: null,
      school_year: null
    }
  },
  computed: {
    required() {
      return this.role && this.role.role_access_level === 'teacher'
    },
    route() {
      let filters = {
        by_unity: this.unity.id,
        by_year: this.school_year.id
      }

      if (this.role.role_access_level === 'teacher') {
        filters['by_teacher_id'] = window.state.teacher_id
      }

      return Routes.classrooms_pt_br_path({ filter: filters, format: 'json' })
    }
  },
  methods: {
    classroomHasBeenSelected(classroom, toFetch = true) {
      EventBus.$emit("set-classroom", this.$data);

      if(toFetch) {
        EventBus.$emit("fetch-teachers", this.selected);
      }
    }
  },
  mounted () {
    this.classroomHasBeenSelected(this.selected, false)
  },
  created () {
    EventBus.$on("set-role", (roleData) => {
      this.role = roleData.selected
    })

    EventBus.$on("set-unity", (unityData) => {
      this.unity = unityData.selected
    })

    EventBus.$on("set-school-year", (schoolYearData) => {
      this.school_year = schoolYearData.selected
    })

    EventBus.$on("fetch-classrooms", async (schoolYear) => {
      this.isLoading = true
      this.selected = null
      this.options = []

      this.classroomHasBeenSelected(this.selected)

      if (schoolYear) {
        await axios
          .get(this.route)
          .then(response => {
            this.options = response.data

            if(response.data.length === 1) {
              this.selected = response.data[0]
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
