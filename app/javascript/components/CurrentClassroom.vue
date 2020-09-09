<template>
  <div id="current-classroom-container"
       class="project-context"
       v-if="this.$store.getters['school_years/isSelected']"
       >
    <span v-bind:class="[required ? 'required' : '', 'label']">Turma</span>

    <input type="hidden" name="user[current_classroom_id]" v-model="selected.id" v-if="selected" />

    <multiselect v-model="selected"
                 :options="options"
                 :searchable="true"
                 :close-on-select="true"
                 track-by="id"
                 label="description"
                 placeholder="Selecione"
                 @input="updateSelects"
                 deselect-label=""
                 select-label=""
                 selected-label="">
      <span slot="noResult">Não encontrado...</span>
      <span slot="noOptions">Não há turmas...</span>
    </multiselect>
  </div>
</template>

<script>
import { mapState  } from 'vuex'

export default {
  name: "b-current-classroom",
  computed: {
    ...mapState({
      required: state => state.classrooms.required,
      options: state => state.classrooms.options
    }),
    selected: {
      get () {
        return this.$store.state.classrooms.selected
      },
      set (value) {
        this.$store.commit('classrooms/setSelected', value)
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
      this.$store.dispatch('setRequired')
      this.$store.dispatch('updateValidation', null, { root: true })
    }
  }
}
</script>

<style>
#current-classroom-container {
  width: 150px;
}
</style>
