import Vue from 'vue/dist/vue.js'
import Vuex from 'vuex'

import classrooms from './modules/classrooms'
import roles from './modules/roles'
import school_years from './modules/school_years'
import teachers from './modules/teachers'
import unities from './modules/unities'
import disciplines from './modules/disciplines'

Vue.use(Vuex)

export default new Vuex.Store({
  state: () => ({
    isValid: null
  }),
  mutations: {
    setIsValid(state, value) {
      state.isValid = value
    }
  },
  actions: {
    updateValidation({ dispatch, commit, getters, rootGetters }) {
      let value = getters['classrooms/isValid'] &&
        getters['disciplines/isValid'] &&
        getters['roles/isValid'] &&
        getters['school_years/isValid'] &&
        getters['teachers/isValid'] &&
        getters['unities/isValid']
      commit('setIsValid', value, { root: true })
    },
    setRequired({ dispatch, commit, getters, rootGetters, rootState }) {
      commit('roles/setRequired', true, { root: true })
      commit('school_years/setRequired', false, { root: true })
      commit('classrooms/setRequired', false, { root: true })
      commit('teachers/setRequired', false, { root: true })
      commit('disciplines/setRequired', false, { root: true })
      commit('unities/setRequired', false, { root: true })

      if(getters['roles/isParentOrStudent']()) {
        return
      }

      commit('school_years/setRequired', true, { root: true })

      if(getters['roles/is']('teacher')) {
        commit('classrooms/setRequired', true, { root: true })
      } else {
        commit('classrooms/setRequired', false, { root: true })
      }

      if(!getters['classrooms/isSelected']) {
        commit('teachers/setRequired', false, { root: true })
        commit('disciplines/setRequired', false, { root: true })
      } else {
        commit('teachers/setRequired', true, { root: true })
        commit('disciplines/setRequired', true, { root: true })
      }

      if(getters['roles/is']('admin')) {
        commit('unities/setRequired', true, { root: true })
      }
    }
  },
  modules: {
    classrooms,
    roles,
    school_years,
    teachers,
    unities,
    disciplines
  }
})
