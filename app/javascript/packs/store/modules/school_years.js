import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'

const school_years = {
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
      commit('set_selected', window.state.current_school_year)
      commit('set_options', window.state.available_school_years)
    },
    fetch({ dispatch, state, commit, rootState, rootGetters }) {
      commit('set_selected', null)
      commit('set_options', [])
      commit('teachers/set_selected', null, { root: true })
      commit('teachers/set_options', [], { root: true })
      commit('classrooms/set_selected', null, { root: true })
      commit('classrooms/set_options', [], { root: true })
      commit('disciplines/set_options', [], { root: true })
      commit('disciplines/set_selected', null, { root: true })

      const route = Routes.years_from_unity_school_calendars_pt_br_path({
        unity_id: rootState.unities.selected,
        only_opened_years: !rootGetters['roles/canChangeSchoolYear'],
        format: 'json'
      })

      axios.get(route)
        .then(response => {
          commit('set_options', response.data.school_calendars)

          if(response.data.school_calendars.length === 1) {
            commit('set_selected', response.data.school_calendars[0].id)

            dispatch('classrooms/fetch', null, { root: true })
          }

        })
    }
  }
}

export default school_years
