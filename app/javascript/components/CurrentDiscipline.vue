<template>
  <div id="current-discipline-container"
       class="project-context col col-sm-2"
       v-if="this.$store.getters['teachers/isSelected']"
       >
    <span v-bind:class="[required ? 'required' : '', 'label']">Disciplina</span>

    <select v-model="selected" name="user[current_discipline_id]">
      <option v-for="option in options" v-bind:value="option.id" :key="option.id">
        {{ option.description }}
      </option>
    </select>
  </div>
</template>

<script>
import { mapState  } from 'vuex'

export default {
  name: "b-current-discipline",
  computed: {
    ...mapState({
      required: state => state.disciplines.required,
      isValid: state => state.disciplines.isValid,
      options: state => state.disciplines.options
    }),
    selected: {
      get () {
        return this.$store.state.disciplines.selected
      },
      set (value) {
        this.$store.commit('disciplines/set_selected', value)
      }
    }
  },
  created() {
    this.$store.dispatch('disciplines/preLoad')
  },
  watch: {
    selected: function(newValue, oldValue) {
      this.$store.dispatch('updateValidation', null, { root: true })
    }
  }
}
</script>
