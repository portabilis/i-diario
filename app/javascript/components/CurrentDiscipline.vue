<template>
  <div id="current-discipline-container" class="project-context col col-sm-2" v-if="options.length">
    <span class="label required">Disciplina</span>
    <select v-model="selected">
      <option v-for="option in options" v-bind:value="option.id" :key="option.id">
        {{ option.description }}
      </option>
    </select>
  </div>
</template>

<script>
import { mapState } from 'vuex'

export default {
  name: "b-current-discipline",
  computed: {
    selected: {
      get () {
        return this.$store.state.disciplines.selected
      },
      set (value) {
        this.$store.commit('disciplines/set_selected', value)
      }
    },
    options: {
      get () {
        return this.$store.state.disciplines.options
      }
    }
  },
  created() {
    this.$store.dispatch('disciplines/preLoad')
  }
}
</script>
