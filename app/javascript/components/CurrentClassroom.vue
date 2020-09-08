<template>
  <div id="current-classroom-container"
       class="project-context col col-sm-2"
       v-if="this.$store.getters['school_years/isSelected']"
       >
    <span v-bind:class="[required ? 'required' : '', 'label']">Turma</span>

    <select v-model="selected" @change="updateSelects" name="user[current_classroom_id]">
      <option v-for="option in options" v-bind:value="option.id" :key="option.id">
        {{ option.description }}
      </option>
    </select>
  </div>
</template>

<script>
import { mapState  } from 'vuex'

export default {
  name: "b-current-classroom",
  computed: {
    ...mapState({
      required: state => state.classrooms.required,
      isValid: state => state.classrooms.isValid,
      options: state => state.classrooms.options
    }),
    selected: {
      get () {
        return this.$store.state.classrooms.selected
      },
      set (value) {
        this.$store.commit('classrooms/set_selected', value)
      }
    }
  },
  created() {
    this.$store.dispatch('classrooms/preLoad')
  },
  methods: {
    updateSelects() {
      this.$store.dispatch('teachers/fetch')
    }
  },
  watch: {
    selected: function(newValue, oldValue) {
      this.$store.dispatch('updateValidation', null, { root: true })
    }
  }
}
</script>
