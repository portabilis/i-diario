<template>
  <div id="current-unity-container" class="project-context col col-sm-2" v-if="options.length" v-show="options.length > 1">
    <span class="label required">Unidade</span>
    <select v-model="selected" @change="updateSelects">
      <option></option>
      <option v-for="option in options" v-bind:value="option.id" :key="option.id">
        {{ option.name }}
      </option>
    </select>
  </div>
</template>

<script>
import { mapState } from 'vuex'

export default {
  name: "b-current-unity",
  computed: {
    selected: {
      get () {
        return this.$store.state.unities.selected
      },
      set (value) {
        this.$store.commit('unities/set_selected', value)
      }
    },
    options: {
      get () {
        return this.$store.state.unities.options
      }
    }
  },
  created() {
    this.$store.dispatch('unities/preLoad')
  },
  methods: {
    updateSelects(e) {
      this.$store.commit('school_years/set_selected', null)
      this.$store.commit('school_years/set_options', [])
      this.$store.commit('teachers/set_selected', null)
      this.$store.commit('teachers/set_options', [])
      this.$store.commit('classrooms/set_selected', null)
      this.$store.commit('classrooms/set_options', [])
      this.$store.commit('disciplines/set_options', [])
      this.$store.commit('disciplines/set_selected', null)

      this.$store.dispatch('school_years/fetch')
    }
  }
}
</script>
