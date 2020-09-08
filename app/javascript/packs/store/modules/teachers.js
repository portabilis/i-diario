import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'

const teachers = {
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
    preLoad({ dispatch, state, commit, rootState, rootGetters }) {
      commit('set_selected', window.state.current_teacher_id)
      commit('set_options', window.state.available_teachers)
    },
    fetch({ dispatch, state, commit, rootState, rootGetters }) {
      commit('set_selected', null)
      commit('set_options', [])
      commit('disciplines/set_options', [], { root: true })
      commit('disciplines/set_selected', null, { root: true })

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
  }
}

export default teachers
