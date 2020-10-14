<template>
  <div id="teacher-profile-container" class="project-context" v-if="displayable">
    <span :class="{ required, label: true  }">
      Disciplina / Área de Conhecimento
    </span>

    <input type="hidden"
           name="user[current_classroom_id]"
           v-model="selected.classroom_id"
           v-if="selected" />

    <input type="hidden"
           name="user[current_knowledge_area_id]"
           v-model="selected.knowledge_area_id"
           v-if="selected" />

    <input type="hidden"
           name="user[current_discipline_id]"
           v-model="selected.discipline_id"
           v-if="selected" />

    <input type="hidden"
           name="user[current_teacher_id]"
           v-model="teacher_id"
           v-if="selected" />

    <multiselect v-model="selected"
                 :options="options"
                 :searchable="true"
                 :close-on-select="true"
                 :placeholder="isLoading ? 'Carregando...' : 'Selecione'"
                 :allow-empty="false"
                 :loading="isLoading"
                 :disabled="anyComponentLoading"
                 :custom-label="labelFormater"
                 @input="teacherProfileHasBeenSelected"
                 track-by="uuid"
                 label="description"
                 deselect-label=""
                 select-label=""
                 selected-label="">

      <template slot="option" slot-scope="props">
        <div>
          <span class="label" v-bind:style="'background: ' + props.option.label_color">{{ props.option.classroom_description }}</span> {{ props.option.description }}
        </div>
      </template>
      <span slot="noResult">Não encontrado...</span>
      <span slot="noOptions">Não há disciplinas...</span>
    </multiselect>
  </div>
</template>

<script>
import axios from 'axios'
import { EventBus  } from "../packs/event-bus.js"

export default {
  name: "b-teacher-profile",
  props: [ 'anyComponentLoading' ],
  data () {
    return {
      options: window.state.profiles,
      selected: window.state.current_profile,
      teacher_id: window.state.teacher_id,
      isLoading: false,
      required: true,
      role: null,
      unity: null,
      classroom_colors: {}
    }
  },
  computed: {
    displayable () {
      return this.isTeacher() && (this.isLoading || this.options.length)
    }
  },
  methods: {
    labelFormater({ description, classroom_description }) {
      return `${classroom_description} - ${description}`
    },
    teacherProfileHasBeenSelected() {
      EventBus.$emit("set-teacher-profile", this.$data)
    },
    route (schoolYear) {
      let filters = {
        by_unity_id: this.unity.id,
        by_school_year: schoolYear.name
      }

      return Routes.available_teacher_profiles_pt_br_path({ filter: filters, format: 'json' })
    },
    isTeacher() {
      return this.role && this.role.role_access_level == "teacher"
    }
  },
  created: function () {
    EventBus.$on("set-role", (roleData) => {
      this.role = roleData.selected
    })

    EventBus.$on("set-unity", (unityData) => {
      this.unity = unityData.selected
    })

    EventBus.$on("fetch-teacher-profiles", async (schoolYear) => {
      this.isLoading = true
      this.selected = null
      this.options = []

      this.teacherProfileHasBeenSelected()

      if (schoolYear) {
        await axios
          .get(this.route(schoolYear))
          .then(({ data }) => {
            this.options = data.teacher_profiles

            if (this.options.length === 1) {
              this.selected = this.options[0]
            } else if (this.options.length === 0) {
              return EventBus.$emit("fetch-classrooms", schoolYear)
            }
          })
      }

      this.isLoading = false
      this.teacherProfileHasBeenSelected()
    })
  },
  mounted () {
    this.teacherProfileHasBeenSelected()
  }
}
</script>

<style>
#teacher-profile-container {
  width: 300px;
}
.multiselect__option--group {
  background-color: #27333B;
  color: white;
  font-weight: bold;
}
@media (max-width: 1365px) {
  #teacher-profile-container {
    width: 100%;
  }
}
</style>
