<template>
  <div id="current-school-year-container" class="project-context col col-sm-2" v-if="options.length">
    <span class="label required">Ano Letivo</span>
    <select v-model="selected" @change="updateSelects">
      <option v-for="option in options" v-bind:value="option.id" :key="option.id">
        {{ option.name }}
      </option>
    </select>
  </div>
</template>

<script>
import { mapState } from 'vuex'

export default {
  name: "b-current-school-year",
  computed: {
    selected: {
      get () {
        return this.$store.state.school_years.selected
      },
      set (value) {
        this.$store.commit('school_years/set_selected', value)
      }
    },
    options: {
      get () {
        return this.$store.state.school_years.options
      }
    }
  },
  created() {
    this.$store.dispatch('school_years/preLoad')
  },
  methods: {
    updateSelects() {
      this.$store.commit('classrooms/set_selected', null)
      this.$store.commit('classrooms/set_options', [])
      this.$store.commit('teachers/set_selected', null)
      this.$store.commit('teachers/set_options', [])
      this.$store.commit('disciplines/set_options', [])
      this.$store.commit('disciplines/set_selected', null)

      this.$store.dispatch('classrooms/fetch')
    }
  }
}
</script>
