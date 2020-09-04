import axios from 'axios'

const classrooms = {
  namespaced: true,
  state: {
    selected: null,
    options: []
  },
  actions: {
    preLoad({commit}) {
      commit('set_selected', window.state.current_classroom_id)
      commit('set_options', window.state.available_classrooms)
    },
    fetch({ state, commit, rootState, rootGetters }) {
      const filters = {
        by_unity: rootState.unities.selected,
        by_year: rootState.school_years.selected
      }

      if(rootGetters['roles/isTeacher']) {
        filters['by_teacher_id'] = window.state.teacher_id
      }

      const route = Routes.classrooms_pt_br_path({
        filter: filters,
        format: 'json'
      })

      axios.get(route)
        .then(response => {
          commit('set_options', response.data)

          if(response.data.length === 1) {
            commit('set_selected', response.data[0].id)
            dispatch('teachers/fetch', null, { root: true })
          }
        })
    }
  },
  mutations: {
    set_selected(state, id) {
      state.selected = id
    },
    set_options(state, classrooms) {
      state.options = classrooms
    }
  }
}

export default classrooms
