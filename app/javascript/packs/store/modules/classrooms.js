import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'

const classrooms = {
  namespaced: true,
  state: {
    selected: null,
    options: [],
    required: false,
    isValid: true
  },
  mutations,
  getters,
  actions: {
    preLoad({commit}) {
      commit('set_selected', window.state.current_classroom_id)
      commit('set_options', window.state.available_classrooms)
    },
    fetch({ dispatch, state, commit, rootState, rootGetters }) {
      commit('set_selected', null)
      commit('set_options', [])
      commit('teachers/set_selected', null, { root: true })
      commit('teachers/set_options', [], { root: true })
      commit('disciplines/set_options', [], { root: true })
      commit('disciplines/set_selected', null, { root: true })

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
  }
}

export default classrooms
