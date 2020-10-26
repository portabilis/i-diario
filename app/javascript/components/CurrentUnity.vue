<template>
  <div id="current-unity-container" class="project-context" v-show="isLoading || required" >
    <span :class="{ required, label: true  }">
      Unidade
    </span>

    <input type="hidden" name="user[current_unity_id]" v-model="selected.id" v-if="selected" />
    <multiselect v-model="selected"
                 :options="options"
                 :searchable="true"
                 :close-on-select="true"
                 :placeholder="isLoading ? 'Carregando...' : 'Selecione'"
                 :allow-empty="false"
                 :loading="isLoading"
                 :disabled="anyComponentLoading"
                 @input="unityHasBeenSelected(selected, true)"
                 track-by="id"
                 label="name"
                 deselect-label=""
                 select-label=""
                 selected-label="">
      <span slot="noResult">Não encontrado...</span>
      <span slot="noOptions">Não há escolas...</span>
    </multiselect>
  </div>
</template>

<script>
import axios from 'axios'
import { EventBus  } from "../packs/event-bus.js"

export default {
  name: "b-current-unity",
  props: [ 'anyComponentLoading' ],
  data () {
    return {
      selected: window.state.current_unity,
      options: window.state.available_unities,
      isLoading: false,
      role: null,
      required: false
    }
  },
  methods: {
    route(role) {
      const filters = {
        by_user_role_id: role.id
      }

      if (role.unity_id) {
        filters['by_unity_id'] = role.unity_id
      }

      return Routes.available_unities_pt_br_path({ format: 'json', filter: filters })
    },
    unityHasBeenSelected(selectedUnity, toFetch = true) {
      EventBus.$emit("set-unity", this.$data);

      if(toFetch) {
        EventBus.$emit("fetch-school-years", selectedUnity);
      }
    }
  },
  mounted () {
    this.unityHasBeenSelected(this.selected, false)
  },
  created () {
    EventBus.$on("set-role", (roleData) => {
      this.role = roleData.selected
      this.required = this.role && this.role.role_access_level === "administrator"
    })

    EventBus.$on("fetch-unities", async (selectedRole) => {
      this.isLoading = true
      this.selected = null
      this.options = []

      this.unityHasBeenSelected(this.selected)

      if (
        selectedRole &&
        selectedRole.role_access_level !== "student" &&
        selectedRole.role_access_level !== "parent"
      ) {
        let route = this.route(selectedRole)

        await axios.get(route)
          .then(({ data }) => {
            this.options = data.unities

            if (this.options.length === 1) {
              this.selected = this.options[0]
            }
          })
      }

      this.isLoading = false
      this.unityHasBeenSelected(this.selected)
    })
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
