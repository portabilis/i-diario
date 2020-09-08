<template>
  <div id="current-school-year-container"
       class="project-context col col-sm-2"
       v-if="this.$store.getters['unities/isSelected']"
       >
    <span v-bind:class="[required ? 'required' : '', 'label']">Ano Letivo</span>

    <select v-model="selected" @change="updateSelects" name="user[current_school_year]">
      <option v-for="option in options" v-bind:value="option.id" :key="option.id">
        {{ option.name }}
      </option>
    </select>
  </div>
</template>

<script>
import { mapState  } from 'vuex'

export default {
  name: "b-current-school-year",
  computed: {
    ...mapState({
      required: state => state.school_years.required,
      isValid: state => state.school_years.isValid,
      options: state => state.school_years.options
    }),
    selected: {
      get () {
        return this.$store.state.school_years.selected
      },
      set (value) {
        this.$store.commit('school_years/set_selected', value)
      }
    }
  },
  created() {
    this.$store.dispatch('school_years/preLoad')
  },
  methods: {
    updateSelects() {
      this.$store.dispatch('classrooms/fetch')
    }
  },
  watch: {
    selected: function(newValue, oldValue) {
      this.$store.dispatch('updateValidation', null, { root: true })
    }
  }
}
</script>
