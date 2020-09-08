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
      let value = this.state.classrooms.isValid &&
        this.state.disciplines.isValid &&
        this.state.roles.isValid &&
        this.state.school_years.isValid &&
        this.state.teachers.isValid &&
        this.state.unities.isValid
      commit('setIsValid', value, { root: true })
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
