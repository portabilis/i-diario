<template>
  <div id="current-unity-container"
       class="project-context"
       v-if="this.$store.getters['roles/isSelected']"
       v-show="options.length > 1"
       >
    <span v-bind:class="[required ? 'required' : '', 'label']">Unidade</span>

    <input type="hidden" name="user[current_unity_id]" v-model="selected.id" v-if="selected" />

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
      <span slot="noOptions">Não há escolas...</span>
    </multiselect>
  </div>
</template>

<script>
import { mapState  } from 'vuex'

export default {
  name: "b-current-unity",
  computed: {
    ...mapState({
      required: state => state.unities.required,
      options: state => state.unities.options
    }),
    selected: {
      get () {
        return this.$store.state.unities.selected
      },
      set (value) {
        this.$store.commit('unities/setSelected', value)
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

<style>
#current-unity-container {
  width: 150px;
}
@media (max-width: 1365px) {
  #current-unity-container {
    width: 100%;
  }
}
</style>
