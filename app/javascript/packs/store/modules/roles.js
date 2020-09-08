import mutations from '../mutations.js'
import getters from '../getters.js'

const roles = {
  namespaced: true,
  state: {
    selected: null,
    options: [],
    required: false,
    isValid: true
  },
  mutations,
  actions: {
    preLoad({commit, getters}) {
      commit('set_selected', window.state.current_role_id)
      commit('set_options', window.state.available_roles)

      if(getters.isTeacher) {
        commit('disciplines/setRequired', true, { root: true })
        commit('classrooms/setRequired', true, { root: true })
      } else {
        commit('disciplines/setRequired', false, { root: true })
        commit('classrooms/setRequired', false, { root: true })
      }

      if(getters.isTeacher || getters.isAdmin || getters.isEmployee) {
        commit('school_years/setRequired', true, { root: true })
        commit('teachers/setRequired', true, { root: true })
      } else {
        commit('school_years/setRequired', false, { root: true })
        commit('teachers/setRequired', false, { root: true })
      }

      if(getters.isAdmin) {
        commit('unities/setRequired', true, { root: true })
      } else {
        commit('unities/setRequired', false, { root: true })
      }
    }
  },
  getters: {
    ...getters,
    getById: (state) => (id) => {
      return state.options.find(option => option.id === id)
    },
    canChangeSchoolYear: function(state, getters) {
      return getters.getById(state.selected).can_change_school_year
    },
    isTeacher: function(state, getters) {
      return getters.getById(state.selected).role_access_level == 'teacher'
    },
    isAdmin: function(state, getters) {
      return getters.getById(state.selected).role_access_level == 'administrator'
    },
    isParent: function(state, getters) {
      return getters.getById(state.selected).role_access_level == 'parent'
    },
    isStudent: function(state, getters) {
      return getters.getById(state.selected).role_access_level == 'student'
    },
    isEmployee: function(state, getters) {
      return getters.getById(state.selected).role_access_level == 'employee'
    },
    unityId: function(state, getters) {
      return getters.getById(state.selected).unity_id
    }
  }
}

export default roles
