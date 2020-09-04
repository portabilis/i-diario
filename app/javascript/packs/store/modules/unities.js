import axios from 'axios'

const unities = {
  namespaced: true,
  state: {
    selected: null,
    options: []
  },
  actions: {
    preLoad({commit}) {
      commit('set_selected', window.state.current_unity_id)
      commit('set_options', window.state.available_unities)
    },
    fetch({ dispatch, state, commit, rootState, rootGetters }) {
      const filters = { }

      // TODO Ver caso professor mais de uma escola
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

          console.log(response.data.unities)
          if(response.data.unities.length === 1) {
            commit('set_selected', response.data.unities[0].id)
            dispatch('school_years/fetch', null, { root: true })
          }
        })
    }
  },
  mutations: {
    set_selected(state, id) {
      state.selected = id
    },
    set_options(state, unities) {
      state.options = unities
    }
  }
}

export default unities
