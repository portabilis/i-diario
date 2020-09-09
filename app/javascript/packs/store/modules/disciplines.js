import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'

const disciplines = {
  namespaced: true,
  state: {
    selected: null,
    options: [],
    required: false,
    isLoading: true
  },
  mutations,
  getters,
  actions: {
    preLoad({commit, getters}) {
      commit('setOptions', window.state.available_disciplines)
      commit('setSelected', getters.getById(window.state.current_discipline_id))
      commit('setIsLoading', false)
    },
    fetch({ dispatch, state, commit, rootState, rootGetters }) {
      commit('setIsLoading', true)
      commit('setOptions', [])
      commit('setSelected', null)

      const filters = {
        by_teacher_id: rootState.teachers.selected.id,
        by_classroom: rootState.classrooms.selected.id,
      }

      const route = Routes.search_disciplines_pt_br_path({
        filter: filters,
        format: 'json'
      })

      axios.get(route)
        .then(response => {
          commit('setOptions', response.data.disciplines)

          if(response.data.disciplines.length === 1) {
            commit('setSelected', response.data.disciplines[0])
          }

          commit('setIsLoading', false)
        })
    }
  }
}

export default disciplines
