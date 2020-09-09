import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'

const teachers = {
  namespaced: true,
  state: {
    selected: null,
    options: [],
    required: false
  },
  mutations,
  getters,
  actions: {
    preLoad({ commit, getters }) {
      commit('setOptions', window.state.available_teachers)
      commit('setSelected', getters.getById(window.state.current_teacher_id))
    },
    fetch({ dispatch, state, commit, rootState, rootGetters }) {
      commit('setSelected', null)
      commit('setOptions', [])
      commit('disciplines/setOptions', [], { root: true })
      commit('disciplines/setSelected', null, { root: true })

      const filters = {
        by_unity_id: rootState.unities.selected.id,
        by_year: rootState.school_years.selected.id,
        by_classroom: rootState.classrooms.selected.id,
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
          commit('setOptions', response.data)

          if(response.data.length === 1) {
            commit('setSelected', response.data[0])

            dispatch('disciplines/fetch', null, { root: true })
          }
        })
    }
  }
}

export default teachers
