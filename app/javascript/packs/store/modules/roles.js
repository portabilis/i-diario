import mutations from '../mutations.js'
import getters from '../getters.js'

const roles = {
  namespaced: true,
  state: {
    selected: null,
    options: [],
    required: false,
    isLoading: true
  },
  mutations,
  actions: {
    preLoad({ commit, getters }) {
      commit('setOptions', window.state.available_roles)
      commit('setSelected', getters.getById(window.state.current_role_id))
      commit('setIsLoading', false)
    }
  },
  getters: {
    ...getters,
    canChangeSchoolYear: function(state, getters) {
      return state.selected.can_change_school_year
    },
    is: (state, getters) => (accessLevel) => {
      return state.selected && state.selected.role_access_level == accessLevel
    },
    isParentOrStudent: (state, getters) => (accessLevel) => {
      return getters.is('parent') || getters.is('student')
    }
  }
}

export default roles
