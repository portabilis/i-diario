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
                 :placeholder="isLoading ? 'Carregando...' : 'Selecione'"
                 :allow-empty="false"
                 :loading="isLoading"
                 :disabled="isLoading"
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
      options: state => state.unities.options,
      isLoading: state => state.unities.isLoading
    }),
    selected: {
      get () {
        return this.$store.state.unities.selected
      },
      set (value) {
        this.$store.dispatch('unities/setSelected', value)
      }
    }
  },
  created() {
    this.$store.dispatch('unities/preLoad')
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
