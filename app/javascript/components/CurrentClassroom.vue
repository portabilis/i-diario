<template>
  <div id="current-classroom-container" class="project-context col col-sm-2" v-if="options.length">
    <span class="label required">Turma</span>
    <select v-model="selected" @change="updateSelects">
      <option v-for="option in options" v-bind:value="option.id" :key="option.id">
        {{ option.description }}
      </option>
    </select>
  </div>
</template>

<script>
import { mapState } from 'vuex'

export default {
  name: "b-current-classroom",
  computed: {
    selected: {
      get () {
        return this.$store.state.classrooms.selected
      },
      set (value) {
        this.$store.commit('classrooms/set_selected', value)
      }
    },
    options: {
      get () {
        return this.$store.state.classrooms.options
      }
    }
  },
  created() {
    this.$store.dispatch('classrooms/preLoad')
  },
  methods: {
    updateSelects() {
      this.$store.commit('teachers/set_selected', null)
      this.$store.commit('teachers/set_options', [])
      this.$store.commit('disciplines/set_options', [])
      this.$store.commit('disciplines/set_selected', null)

      this.$store.dispatch('teachers/fetch')
    }
  }
}
</script>
