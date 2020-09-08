import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'

const unities = {
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
      commit('set_selected', window.state.current_unity_id)
      commit('set_options', window.state.available_unities)
    },
    fetch({ dispatch, state, commit, rootState, rootGetters }) {
      commit('set_selected', null, { root: true })
      commit('set_options', [], { root: true })
      commit('school_years/set_selected', null, { root: true })
      commit('school_years/set_options', [], { root: true })
      commit('classrooms/set_selected', null, { root: true })
      commit('classrooms/set_options', [], { root: true })
      commit('teachers/set_selected', null, { root: true })
      commit('teachers/set_options', [], { root: true })
      commit('disciplines/set_options', [], { root: true })
      commit('disciplines/set_selected', null, { root: true })

      const filters = { }

      if(rootGetters['roles/unityId']) {
        filters['by_id'] = rootGetters['roles/unityId']
      }

      const route = Routes.search_unities_pt_br_path({
        format: 'json',
        per: 9999999,
        filter: filters
      })

      axios.get(route)
        .then(response => {
          commit('set_options', response.data.unities)

          if(response.data.unities.length === 1) {
            commit('set_selected', response.data.unities[0].id)

            dispatch('school_years/fetch', null, { root: true })
          }

        })
    }
  }
}

export default unities
