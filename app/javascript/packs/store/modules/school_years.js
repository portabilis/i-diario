import axios from 'axios'

const school_years = {
  namespaced: true,
  state: {
    selected: null,
    options: []
  },
  actions: {
    preLoad({commit}) {
      commit('set_selected', window.state.current_school_year)
      commit('set_options', window.state.available_school_years)
    },
    fetch({ dispatch, state, commit, rootState, rootGetters }) {
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
  },
  mutations: {
    set_selected(state, id) {
      state.selected = id
    },
    set_options(state, school_years) {
      state.options = school_years
    }
  }
}

export default school_years
