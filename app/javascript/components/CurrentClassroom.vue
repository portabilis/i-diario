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
                 :placeholder="isLoading ? 'Carregando...' : 'Selecione'"
                 :allow-empty="false"
                 :loading="isLoading"
                 :disabled="isLoading"
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
      options: state => state.classrooms.options,
      isLoading: state => state.classrooms.isLoading
    }),
    selected: {
      get () {
        return this.$store.state.classrooms.selected
      },
      set (value) {
        this.$store.dispatch('classrooms/setSelected', value)
      }
    }
  },
  created() {
    this.$store.dispatch('classrooms/preLoad')
  }
}
</script>

<style>
#current-classroom-container {
  width: 150px;
}
@media (max-width: 1365px) {
  #current-classroom-container {
    width: 100%;
  }
}
</style>
