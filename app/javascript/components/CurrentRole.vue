<template>
  <div id="current-role-container" class="project-context" v-show="selected && options.length > 1">
    <span :class="{ required, label: true  }">
      Perfil
    </span>

    <input type="hidden" name="user[current_user_role_id]" v-model="selected.id" v-if="selected" />
    <multiselect v-model="selected"
                 :options="options"
                 :searchable="true"
                 :close-on-select="true"
                 :placeholder="isLoading ? 'Carregando...' : 'Selecione'"
                 :allow-empty="false"
                 :loading="isLoading"
                 :disabled="anyComponentLoading"
                 track-by="id"
                 label="name"
                 @input="roleHasBeenSelected(selected, true)"
                 deselect-label=""
                 select-label=""
                 selected-label="">
      <span slot="noResult">Não encontrado...</span>
      <span slot="noOptions">Não há perfis...</span>
    </multiselect>
  </div>
</template>

<script>
import { EventBus  } from "../packs/event-bus.js";

export default {
  name: "b-current-role",
  props: [ 'anyComponentLoading' ],
  data () {
    return {
      options: window.state.available_roles,
      selected: window.state.current_role,
      required: false,
      isLoading: false
    }
  },
  methods: {
    roleHasBeenSelected(selectedRole, toFetch = true) {
      EventBus.$emit("set-role", this.$data)

      if(toFetch) {
        EventBus.$emit("fetch-unities", selectedRole)
      }
    }
  },
  mounted () {
    this.roleHasBeenSelected(this.selected, false)
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
