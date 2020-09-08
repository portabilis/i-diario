<template>
  <div id="current-unity-container"
       class="project-context col col-sm-2"
       v-if="this.$store.getters['roles/isSelected']"
       v-show="options.length > 1"
       >
    <span v-bind:class="[required ? 'required' : '', 'label']">Unidade</span>

    <select v-model="selected" @change="updateSelects" name="user[current_unity_id]">
      <option></option>
      <option v-for="option in options" v-bind:value="option.id" :key="option.id">
        {{ option.name }}
      </option>
    </select>
  </div>
</template>

<script>
import { mapState  } from 'vuex'

export default {
  name: "b-current-unity",
  computed: {
    ...mapState({
      required: state => state.unities.required,
      isValid: state => state.unities.isValid,
      options: state => state.unities.options
    }),
    selected: {
      get () {
        return this.$store.state.unities.selected
      },
      set (value) {
        this.$store.commit('unities/set_selected', value)
      }
    }
  },
  created() {
    this.$store.dispatch('unities/preLoad')
  },
  methods: {
    updateSelects(e) {
      this.$store.dispatch('school_years/fetch')
    }
  },
  watch: {
    selected: function(newValue, oldValue) {
      this.$store.dispatch('updateValidation', null, { root: true })
    }
  }
}
</script>
