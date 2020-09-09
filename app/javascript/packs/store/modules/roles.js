import mutations from '../mutations.js'
import getters from '../getters.js'

const roles = {
  namespaced: true,
  state: {
    selected: null,
    options: [],
    required: false
  },
  mutations,
  actions: {
    preLoad({ commit, getters }) {
      commit('setOptions', window.state.available_roles)
      commit('setSelected', getters.getById(window.state.current_role_id))
    }
  },
  getters: {
    ...getters,
    canChangeSchoolYear: function(state, getters) {
      return getters.getById(state.selected.id).can_change_school_year
    },
    isTeacher: function(state, getters) {
      return getters.getById(state.selected.id).role_access_level == 'teacher'
    },
    isAdmin: function(state, getters) {
      return getters.getById(state.selected.id).role_access_level == 'administrator'
    },
    isParent: function(state, getters) {
      return getters.getById(state.selected.id).role_access_level == 'parent'
    },
    isStudent: function(state, getters) {
      return getters.getById(state.selected.id).role_access_level == 'student'
    },
    isEmployee: function(state, getters) {
      return getters.getById(state.selected.id).role_access_level == 'employee'
    },
    unityId: function(state, getters) {
      return getters.getById(state.selected.id).unity_id
    }
  }
}

export default roles
