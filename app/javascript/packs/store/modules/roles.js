const roles = {
  namespaced: true,
  state: {
    selected: null,
    options: []
  },
  actions: {
    preLoad({commit}) {
      commit('set_selected', window.state.current_role_id)
      commit('set_options', window.state.available_roles)
    }
  },
  getters: {
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
    unityId: function(state, getters) {
      return getters.getById(state.selected).unity_id
    }
  },
  mutations: {
    set_selected(state, id) {
      state.selected = id
    },
    set_options(state, roles) {
      state.options = roles
    }
  },
}

export default roles
