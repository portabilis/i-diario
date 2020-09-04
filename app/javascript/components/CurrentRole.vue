<template>
  <div id="current-role-container" class="project-context col col-sm-2" v-if="options.length > 1">
    <span class="label required">Perfil</span>
    <select v-model="selected" @change="updateSelects">
      <option v-for="option in options"
              v-bind:value="option.id"
              :key="option.id">
        {{ option.name }}
      </option>
    </select>
  </div>
</template>

<script>
import { mapState } from 'vuex'

export default {
  name: "b-current-role",
  computed: {
    selected: {
      get () {
        return this.$store.state.roles.selected
      },
      set (value) {
        this.$store.commit('roles/set_selected', value)
      }
    },
    options: {
      get () {
        return this.$store.state.roles.options
      }
    }
  },
  created() {
    this.$store.dispatch('roles/preLoad')
  },
  methods: {
    updateSelects() {
      this.$store.commit('unities/set_selected', null)
      this.$store.commit('unities/set_options', [])
      this.$store.commit('school_years/set_selected', null)
      this.$store.commit('school_years/set_options', [])
      this.$store.commit('classrooms/set_selected', null)
      this.$store.commit('classrooms/set_options', [])
      this.$store.commit('teachers/set_selected', null)
      this.$store.commit('teachers/set_options', [])
      this.$store.commit('disciplines/set_options', [])
      this.$store.commit('disciplines/set_selected', null)

      this.$store.dispatch('unities/fetch')
    }
  }
}
</script>
