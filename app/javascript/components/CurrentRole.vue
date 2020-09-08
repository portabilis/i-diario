<template>
  <div id="current-role-container"
       class="project-context col col-sm-2"
       v-show="options.length > 1"
       >
    <span v-bind:class="[required ? 'required' : '', 'label']">Perfil</span>

    <select v-model="selected" @change="updateSelects" name="user[current_user_role_id]">
      <option v-for="option in options"
              v-bind:value="option.id"
              :key="option.id">
        {{ option.name }}
      </option>
    </select>
  </div>
</template>

<script>
import { mapState  } from 'vuex'

export default {
  name: "b-current-role",
  computed: {
    ...mapState({
      required: state => state.roles.required,
      isValid: state => state.roles.isValid,
      options: state => state.roles.options
    }),
    selected: {
      get () {
        return this.$store.state.roles.selected
      },
      set (value) {
        this.$store.commit('roles/set_selected', value)
      }
    }
  },
  created() {
    this.$store.dispatch('roles/preLoad')
  },
  methods: {
    updateSelects() {
      this.$store.dispatch('unities/fetch')
    }
  },
  watch: {
    selected: function(newValue, oldValue) {
      this.$store.dispatch('updateValidation', null, { root: true })
    }
  }
}
</script>
