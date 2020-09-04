import axios from 'axios'

const disciplines = {
  namespaced: true,
  state: {
    selected: null,
    options: []
  },
  actions: {
    preLoad({commit}) {
      commit('set_selected', window.state.current_discipline_id)
      commit('set_options', window.state.available_disciplines)
    },
    fetch({ state, commit, rootState, rootGetters }) {
      // TODO
      // if (profileRole.role.access_level === 'teacher') {
      //   filters['by_id'] = teacherId;
      // }
      const filters = {
        by_teacher_id: rootState.teachers.selected,
        by_classroom: rootState.classrooms.selected,
      }

      const route = Routes.search_disciplines_pt_br_path({
        filter: filters,
        format: 'json'
      })

      axios.get(route)
        .then(response => {
          commit('set_options', response.data.disciplines)

          if(response.data.disciplines.length === 1) {
            commit('set_selected', response.data.disciplines[0].id)
          }
        })
    }
  },
  mutations: {
    set_selected(state, id) {
      state.selected = id
    },
    set_options(state, disciplines) {
      state.options = disciplines
    }
  }
}

export default disciplines
