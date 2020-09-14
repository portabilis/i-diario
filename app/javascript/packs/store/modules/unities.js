import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'
import actions from '../actions.js'
import defaultState from '../state.js'

const unities = {
  namespaced: true,
  state: {
    ...defaultState,
    required: false,
    isLoading: true,
    fetchAssociation: 'school_years/fetch'
  },
  mutations,
  getters,
  actions: {
    ...actions,
    preLoad({ dispatch, commit, getters }) {
      commit('setOptions', window.state.available_unities)
      commit('setSelected', getters.getById(window.state.current_unity_id))
      commit('setIsLoading', false)
    },
    fetch({ dispatch, state, commit, rootGetters, rootState }) {
      commit('resetState')
      commit('school_years/resetState', null, { root: true })
      commit('classrooms/resetState', null, { root: true })
      commit('teachers/resetState', null, { root: true })
      commit('disciplines/resetState', null, { root: true })

      if(rootGetters['roles/isParentOrStudent']()) {
        return
      }

      const filters = { }

      if(rootState.roles.selected && rootState.roles.selected.unity_id) {
        filters['by_id'] = rootState.roles.selected.unity_id
      }

      const route = Routes.search_unities_pt_br_path({
        format: 'json',
        per: 9999999,
        filter: filters
      })

      axios.get(route)
        .then(response => {
          commit('setOptions', response.data.unities)

          if(response.data.unities.length === 1) {
            dispatch('setSelected', response.data.unities[0])
          }

          commit('setIsLoading', false)
        })
        .finally(() => commit('setIsLoading', false))
    }
  }
}

export default unities
