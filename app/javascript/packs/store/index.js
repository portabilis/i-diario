import Vue from 'vue/dist/vue.js'
import Vuex from 'vuex'
import _ from 'lodash'

import classrooms from './modules/classrooms'
import disciplines from './modules/disciplines'
import roles from './modules/roles'
import school_years from './modules/school_years'
import teachers from './modules/teachers'
import unities from './modules/unities'

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
    setRequired({ commit, getters }) {
      commit('roles/setRequired', true, { root: true })
      commit('school_years/setRequired', false, { root: true })
      commit('classrooms/setRequired', false, { root: true })
      commit('teachers/setRequired', true, { root: true })
      commit('disciplines/setRequired', false, { root: true })
      commit('unities/setRequired', false, { root: true })

      if(!getters['roles/isTeacher'] && !getters['roles/isAdmin'] && !getters['roles/isEmployee']) {
        return
      }

      commit('school_years/setRequired', true, { root: true })

      if(getters['roles/isTeacher']) {
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

      if(getters['roles/isAdmin']) {
        commit('unities/setRequired', true, { root: true })
      }
    }
  },
  modules: {
    classrooms,
    disciplines,
    roles,
    school_years,
    teachers,
    unities
  }
})
