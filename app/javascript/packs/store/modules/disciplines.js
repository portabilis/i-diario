import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'

const disciplines = {
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
      commit('set_selected', window.state.current_discipline_id)
      commit('set_options', window.state.available_disciplines)
    },
    fetch({ dispatch, state, commit, rootState, rootGetters }) {
      commit('set_options', [])
      commit('set_selected', null)

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
  }
}

export default disciplines
