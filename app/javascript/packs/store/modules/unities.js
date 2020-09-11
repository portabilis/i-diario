import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'

const unities = {
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
      commit('setOptions', window.state.available_unities)
      commit('setSelected', getters.getById(window.state.current_unity_id))
      commit('setIsLoading', false)
    },
    fetch({ dispatch, state, commit, rootGetters, rootState }) {
      commit('setIsLoading', true)
      commit('setSelected', null)
      commit('setOptions', [])
      commit('school_years/setSelected', null, { root: true })
      commit('school_years/setOptions', [], { root: true })
      commit('classrooms/setSelected', null, { root: true })
      commit('classrooms/setOptions', [], { root: true })
      commit('teachers/setSelected', null, { root: true })
      commit('teachers/setOptions', [], { root: true })
      commit('knowledge_area_disciplines/setOptions', [], { root: true })
      commit('knowledge_area_disciplines/setSelected', null, { root: true })

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
            commit('setSelected', response.data.unities[0])

            dispatch('school_years/fetch', null, { root: true })
          }

          commit('setIsLoading', false)
        })
    }
  }
}

export default unities
