<template>
  <div id="current-teacher-container"
       class="project-context"
       v-if="this.$store.getters['classrooms/isSelected']"
       v-show="!this.$store.getters['roles/isTeacher']" >
    <span v-bind:class="[required ? 'required' : '', 'label']">Professor</span>

    <input type="hidden" name="user[current_teacher_id]" v-model="selected.id" v-if="selected" />

    <multiselect v-model="selected"
                 :options="options"
                 :searchable="true"
                 :close-on-select="true"
                 track-by="id"
                 label="name"
                 placeholder="Selecione"
                 @input="updateSelects"
                 :allow-empty="false"
                 deselect-label=""
                 select-label=""
                 selected-label="">
      <span slot="noResult">Não encontrado...</span>
      <span slot="noOptions">Não há professores...</span>
    </multiselect>
  </div>
</template>

<script>
import { mapState  } from 'vuex'

export default {
  name: "b-current-teacher",
  computed: {
    ...mapState({
      required: state => state.teachers.required,
      options: state => state.teachers.options
    }),
    selected: {
      get () {
        return this.$store.state.teachers.selected
      },
      set (value) {
        this.$store.commit('teachers/setSelected', value)
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

<style>
#current-teacher-container {
  width: 150px;
}
</style>
