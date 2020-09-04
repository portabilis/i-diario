import Vue from 'vue/dist/vue.js'
import Vuex from 'vuex'

import classrooms from './modules/classrooms'
import disciplines from './modules/disciplines'
import roles from './modules/roles'
import school_years from './modules/school_years'
import teachers from './modules/teachers'
import unities from './modules/unities'

Vue.use(Vuex)

export default new Vuex.Store({
  modules: {
    classrooms,
    disciplines,
    roles,
    school_years,
    teachers,
    unities
  }
})
