<template>
  <div id="current-school-year-container" class="project-context" v-show="isLoading || unity">
    <span :class="{ required, label: true  }">
      Ano Letivo
    </span>

    <input type="hidden" name="user[current_school_year]" v-model="selected.id" v-if="selected" />
    <multiselect v-model="selected"
                 :options="options"
                 :searchable="false"
                 :close-on-select="true"
                 track-by="id"
                 label="name"
                 :placeholder="isLoading ? 'Carregando...' : 'Selecione'"
                 :allow-empty="false"
                 :loading="isLoading"
                 :disabled="anyComponentLoading"
                 @input="schoolYearHasBeenSelected(selected, true)"
                 deselect-label=""
                 select-label=""
                 selected-label="">
      <span slot="noResult">Não encontrado...</span>
      <span slot="noOptions">Não há anos letivos...</span>
    </multiselect>
  </div>
</template>

<script>
import axios from 'axios'
import { EventBus  } from "../packs/event-bus.js"

export default {
  name: "b-current-school-year",
  props: [ 'anyComponentLoading', 'byTeacherProfile' ],
  data() {
    return {
      options: window.state.available_school_years,
      selected: window.state.current_school_year,
      isLoading: false,
      role: null,
      unity: null,
      required: false
    }
  },
  methods: {
    route(unity) {
      return Routes.available_school_years_pt_br_path({
        filter: {
          by_unity_id: unity.id,
          by_user_role_id: this.role.id,
        },
        format: 'json'
      })
    },
    schoolYearHasBeenSelected(schoolYear, toFetch = true) {
      EventBus.$emit("set-school-year", this.$data);

      if (toFetch) {
        if (this.role.role_access_level === "teacher") {
          EventBus.$emit("fetch-teacher-profiles", schoolYear)
        } else {
          EventBus.$emit("fetch-classrooms", schoolYear)
        }
      }
    }
  },
  mounted () {
    this.schoolYearHasBeenSelected(this.selected, false)
  },
  created () {
    EventBus.$on("set-role", (roleData) => {
      this.role = roleData.selected
      this.required = this.role && this.role.role_access_level !== 'parent' && this.role.role_access_level !== 'student'
    })

    EventBus.$on("set-unity", (unityData) => {
      this.unity = unityData.selected
    })

    EventBus.$on("fetch-school-years", async(unity) => {
      this.isLoading = true
      this.selected = null
      this.options = []

      this.schoolYearHasBeenSelected(this.selected)

      if (unity) {
        let route = this.route(unity)

        await axios.get(route)
          .then(({ data }) => {
            this.options = data.school_years

            if(this.options.length === 1) {
              this.selected = this.options[0]
            }
          })
      }

      this.isLoading = false
      this.schoolYearHasBeenSelected(this.selected)
    })
  }
}
</script>

<style>
#current-school-year-container {
  width: 100px;
}
@media (max-width: 1365px) {
  #current-school-year-container {
    width: 100%;
  }
}
</style>
