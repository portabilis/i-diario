import axios from 'axios'

const teachers = {
  namespaced: true,
  state: {
    selected: null,
    options: []
  },
  actions: {
    preLoad({commit}) {
      commit('set_selected', window.state.current_teacher_id)
      commit('set_options', window.state.available_teachers)
    },
    fetch({ dispatch, state, commit, rootState, rootGetters }) {
      const filters = {
        by_unity_id: rootState.unities.selected,
        by_year: rootState.school_years.selected,
        by_classroom: rootState.classrooms.selected,
      }

      if(rootGetters['roles/isTeacher']) {
        filters['by_id'] = window.state.teacher_id
      }

      const route = Routes.teachers_pt_br_path({
        filter: filters,
        format: 'json'
      })

      axios.get(route)
        .then(response => {
          commit('set_options', response.data)

          if(response.data.length === 1) {
            commit('set_selected', response.data[0].id)
            dispatch('disciplines/fetch', null, { root: true })
          }
        })
    }
  },
  mutations: {
    set_selected(state, id) {
      state.selected = id
    },
    set_options(state, teachers) {
      state.options = teachers
    }
  }
}

export default teachers
