<template>
  <div id="current-teacher-container"
       class="project-context col col-sm-2"
       v-if="options.length"
       v-show="!this.$store.getters['roles/isTeacher']" >
    <span class="label required">Professor</span>
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
  name: "b-current-teacher",
  computed: {
    selected: {
      get () {
        return this.$store.state.teachers.selected
      },
      set (value) {
        this.$store.commit('teachers/set_selected', value)
      }
    },
    options: {
      get () {
        return this.$store.state.teachers.options
      }
    }
  },
  created() {
    this.$store.dispatch('teachers/preLoad')
  },
  methods: {
    updateSelects() {
      this.$store.commit('disciplines/set_options', [])
      this.$store.commit('disciplines/set_selected', null)

      this.$store.dispatch('disciplines/fetch')
    }
  }
}
</script>
