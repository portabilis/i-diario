<template>
  <div id="current-discipline-container"
       class="project-context"
       v-if="this.$store.getters['teachers/isSelected']"
       >
    <span v-bind:class="[required ? 'required' : '', 'label']">Disciplina</span>

    <input type="hidden" name="user[current_discipline_id]" v-model="selected.id" v-if="selected" />

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
      <span slot="noOptions">Não há disciplinas...</span>
    </multiselect>
  </div>
</template>

<script>
import { mapState  } from 'vuex'

export default {
  name: "b-current-discipline",
  computed: {
    ...mapState({
      required: state => state.disciplines.required,
      options: state => state.disciplines.options,
      isLoading: state => state.disciplines.isLoading
    }),
    selected: {
      get () {
        return this.$store.state.disciplines.selected
      },
      set (value) {
        this.$store.commit('disciplines/setSelected', value)
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

<style>
#current-discipline-container {
  width: 150px;
}
@media (max-width: 1365px) {
  #current-discipline-container {
    width: 100%;
  }
}
</style>
