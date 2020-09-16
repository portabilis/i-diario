<template>
  <div id="current-discipline-container" class="project-context" v-if="isLoading || options.length">
    <span :class="{ required, label: true  }">
      Disciplina
    </span>

    <input type="hidden" name="user[current_discipline_id]" v-model="selected.id" v-if="selected" />
    <multiselect v-model="selected"
                 :options="options"
                 :searchable="true"
                 :close-on-select="true"
                 :placeholder="isLoading ? 'Carregando...' : 'Selecione'"
                 :allow-empty="false"
                 :loading="isLoading"
                 :disabled="anyComponentLoading"
                 @input="disciplineHasBeenSelected"
                 track-by="id"
                 label="description"
                 deselect-label=""
                 select-label=""
                 selected-label="">
      <span slot="noResult">Não encontrado...</span>
      <span slot="noOptions">Não há disciplinas...</span>
    </multiselect>
  </div>
</template>

<script>
import axios from 'axios'
import { EventBus  } from "../packs/event-bus.js"

export default {
  name: "b-current-discipline",
  props: [ 'anyComponentLoading' ],
  data () {
    return {
      options: window.state.available_disciplines,
      selected: window.state.current_discipline,
      isLoading: false,
      classroom: null,
      role: null
    }
  },
  computed: {
    required() {
      return this.role && this.role.role_access_level !== 'parent' && this.role.role_access_level !== 'student'
    }
  },
  methods: {
    disciplineHasBeenSelected() {
      EventBus.$emit("set-discipline", this.$data)
    },
    route (teacher) {
      let filters = {
        by_teacher_id: teacher.id,
        by_classroom: this.classroom.id,
      }

      return Routes.search_disciplines_pt_br_path({ filter: filters, format: 'json' })
    }
  },
  created: function () {
    EventBus.$on("set-classroom", (classroomData) => {
      this.classroom = classroomData.selected
    })

    EventBus.$on("set-role", (roleData) => {
      this.role = roleData.selected
    })

    EventBus.$on("fetch-disciplines", async (teacher) => {
      this.isLoading = true
      this.selected = null
      this.options = []

      this.disciplineHasBeenSelected()

      if (teacher) {
        await axios
          .get(this.route(teacher))
          .then(response => {
            this.options = response.data.disciplines

            if (response.data.disciplines.length === 1) {
              this.selected = response.data.disciplines[0]
            }
          })
      }

      this.isLoading = false
      this.disciplineHasBeenSelected()
    })
  },
  mounted () {
    this.disciplineHasBeenSelected()
  }
}
</script>

<style>
#current-discipline-container {
  width: 150px;
}
@media (max-width: 1365px) {
  #current-discipline-container {
    width: 100%;
  }
}
</style>
