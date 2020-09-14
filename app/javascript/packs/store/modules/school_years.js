import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'
import actions from '../actions.js'
import defaultState from '../state.js'

const school_years = {
  namespaced: true,
  state: {
    ...defaultState,
    required: false,
    isLoading: true,
    fetchAssociation: 'classrooms/fetch'
  },
  mutations,
  getters,
  actions: {
    ...actions,
    preLoad({ dispatch, commit, getters }) {
      commit('setOptions', window.state.available_school_years)
      commit('setSelected', getters.getById(window.state.current_school_year))
      commit('setIsLoading', false)
    },
    fetch({ dispatch, state, commit, rootState, rootGetters }) {
      commit('resetState')
      commit('teachers/resetState', null, { root: true })
      commit('classrooms/resetState', null, { root: true })
      commit('disciplines/resetState', null, { root: true })

      const route = Routes.years_from_unity_school_calendars_pt_br_path({
        unity_id: rootState.unities.selected.id,
        only_opened_years: !rootGetters['roles/canChangeSchoolYear'],
        format: 'json'
      })

      axios.get(route)
        .then(response => {
          commit('setOptions', response.data.school_calendars)

          if(response.data.school_calendars.length === 1) {
            dispatch('setSelected', response.data.school_calendars[0])
          }
        })
        .finally(() => commit('setIsLoading', false))
    }
  }
}

export default school_years
