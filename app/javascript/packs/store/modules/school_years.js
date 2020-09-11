import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'

const school_years = {
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
      commit('setOptions', window.state.available_school_years)
      commit('setSelected', getters.getById(window.state.current_school_year))
      commit('setIsLoading', false)
    },
    fetch({ dispatch, state, commit, rootState, rootGetters }) {
      commit('setIsLoading', true)
      commit('setSelected', null)
      commit('setOptions', [])
      commit('teachers/setSelected', null, { root: true })
      commit('teachers/setOptions', [], { root: true })
      commit('classrooms/setSelected', null, { root: true })
      commit('classrooms/setOptions', [], { root: true })
      commit('disciplines/setOptions', [], { root: true })
      commit('disciplines/setSelected', null, { root: true })

      const route = Routes.years_from_unity_school_calendars_pt_br_path({
        unity_id: rootState.unities.selected.id,
        only_opened_years: !rootGetters['roles/canChangeSchoolYear'],
        format: 'json'
      })

      axios.get(route)
        .then(response => {
          commit('setOptions', response.data.school_calendars)

          if(response.data.school_calendars.length === 1) {
            commit('setSelected', response.data.school_calendars[0])

            dispatch('classrooms/fetch', null, { root: true })
          }

          commit('setIsLoading', false)
        })
    }
  }
}

export default school_years
