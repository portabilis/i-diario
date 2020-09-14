<template>
  <div id="current-role-container"
       class="project-context"
       v-show="options.length > 1"
       >
    <span v-bind:class="[required ? 'required' : '', 'label']">Perfil</span>

    <input type="hidden" name="user[current_user_role_id]" v-model="selected.id" v-if="selected" />

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
      <span slot="noOptions">Não há perfis...</span>
    </multiselect>
  </div>
</template>

<script>
import { mapState  } from 'vuex'

export default {
  name: "b-current-role",
  computed: {
    ...mapState({
      required: state => state.roles.required,
      options: state => state.roles.options,
      isLoading: state => state.roles.isLoading
    }),
    selected: {
      get () {
        return this.$store.state.roles.selected
      },
      set (value) {
        this.$store.dispatch('roles/setSelected', value)
      }
    }
  },
  created() {
    this.$store.dispatch('roles/preLoad')
  }
}
</script>

<style>
#current-role-container {
  width: 150px;
}
@media (max-width: 1365px) {
  #current-role-container {
    width: 100%;
  }
}
</style>
