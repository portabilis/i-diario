<template>
  <div id="current-teacher-container"
       class="project-context"
       v-if="this.$store.getters['classrooms/isSelected']"
       v-show="!this.$store.getters['roles/is']('teacher')" >

    <span :class="{ required, label: true  }">Professor</span>

    <input type="hidden" name="user[current_teacher_id]" v-model="selected.id" v-if="selected" />

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
      options: state => state.teachers.options,
      isLoading: state => state.teachers.isLoading
    }),
    selected: {
      get () {
        return this.$store.state.teachers.selected
      },
      set (value) {
        this.$store.dispatch('teachers/setSelected', value)
      }
    }
  },
  created() {
    this.$store.dispatch('teachers/preLoad')
  }
}
</script>

<style>
#current-teacher-container {
  width: 150px;
}
@media (max-width: 1365px) {
  #current-teacher-container {
    width: 100%;
  }
}
</style>
