<template>
  <div id="current-school-year-container"
       class="project-context"
       v-if="this.$store.getters['unities/isSelected']"
       >
    <span v-bind:class="[required ? 'required' : '', 'label']">Ano Letivo</span>

    <input type="hidden" name="user[current_school_year]" v-model="selected.id" v-if="selected" />

    <multiselect v-model="selected"
                 :options="options"
                 :searchable="false"
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
      <span slot="noOptions">Não há anos letivos...</span>
    </multiselect>
  </div>
</template>

<script>
import { mapState  } from 'vuex'

export default {
  name: "b-current-school-year",
  computed: {
    ...mapState({
      required: state => state.school_years.required,
      options: state => state.school_years.options
    }),
    selected: {
      get () {
        return this.$store.state.school_years.selected
      },
      set (value) {
        this.$store.commit('school_years/setSelected', value)
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

<style>
#current-school-year-container {
  width: 100px;
}
</style>
