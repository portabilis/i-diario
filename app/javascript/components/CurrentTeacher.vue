<template>
  <div id="current-teacher-container"
       class="project-context col col-sm-2"
       v-if="this.$store.getters['classrooms/isSelected']"
       v-show="!this.$store.getters['roles/isTeacher']" >
    <span v-bind:class="[required ? 'required' : '', 'label']">Professor</span>

    <select v-model="selected" @change="updateSelects" name="user[current_teacher_id]">
      <option v-for="option in options" v-bind:value="option.id" :key="option.id">
        {{ option.name }}
      </option>
    </select>
  </div>
</template>

<script>
import { mapState  } from 'vuex'

export default {
  name: "b-current-teacher",
  computed: {
    ...mapState({
      required: state => state.teachers.required,
      isValid: state => state.teachers.isValid,
      options: state => state.teachers.options
    }),
    selected: {
      get () {
        return this.$store.state.teachers.selected
      },
      set (value) {
        this.$store.commit('teachers/set_selected', value)
      }
    }
  },
  created() {
    this.$store.dispatch('teachers/preLoad')
  },
  methods: {
    updateSelects() {
      this.$store.dispatch('disciplines/fetch')
    }
  },
  watch: {
    selected: function(newValue, oldValue) {
      this.$store.dispatch('updateValidation', null, { root: true })
    }
  }
}
</script>
