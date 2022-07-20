<template>
  <div id="current-discipline-container"
       class="project-context"
       v-if="displayable">
    <span :class="{ required, label: true  }">
      Disciplina / Área de Conhecimento
    </span>

    <input type="hidden"
           name="user[current_knowledge_area_id]"
           v-model="selected.knowledge_area_id"
           v-if="selected" />

    <input type="hidden"
           name="user[current_discipline_id]"
           v-model="selected.discipline_id"
           v-if="selected" />

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
  props: [ 'anyComponentLoading', 'byTeacherProfile' ],
  data () {
    return {
      options: window.state.available_disciplines,
      selected: window.state.current_discipline,
      isLoading: false,
      classroom: null,
      role: null,
      required: false
    }
  },
  computed: {
    displayable () {
      return (this.isLoading || this.options.length) && this.classroom && !this.byTeacherProfile
    }
  },
  methods: {
    setRequired() {
      if (this.classroom && _.isEmpty(this.classroom)) {
        this.required = false
        return
      }

      this.required = this.role && this.role.role_access_level !== 'parent' && this.role.role_access_level !== 'student'
    },
    disciplineHasBeenSelected() {
      EventBus.$emit("set-discipline", this.$data)
    },
    route (teacher) {
      let filters = {
        by_teacher_id: teacher.id,
        by_classroom_id: this.classroom.id,
      }

      return Routes.available_disciplines_pt_br_path({ filter: filters, format: 'json' })
    }
  },
  created: function () {
    EventBus.$on("set-classroom", (classroomData) => {
      this.classroom = classroomData.selected
      this.setRequired()
    })

    EventBus.$on("set-role", (roleData) => {
      this.role = roleData.selected
      this.setRequired()
    })

    EventBus.$on("fetch-disciplines", async (teacher) => {
      this.isLoading = true
      this.selected = null
      this.options = []

      this.disciplineHasBeenSelected()

      if (teacher) {
        await axios
          .get(this.route(teacher))
          .then(({ data }) => {
            this.options = data.disciplines

            if (this.options.length === 1) {
              this.selected = this.options[0]
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
  width: 225px;
}
@media (max-width: 1365px) {
  #current-discipline-container {
    width: 100%;
  }
}
</style>
