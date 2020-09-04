import Vue from 'vue/dist/vue.js'

import CurrentRole from '../components/CurrentRole.vue'
import CurrentUnity from '../components/CurrentUnity.vue'
import CurrentSchoolYear from '../components/CurrentSchoolYear.vue'
import CurrentClassroom from '../components/CurrentClassroom.vue'
import CurrentTeacher from '../components/CurrentTeacher.vue'
import CurrentDiscipline from '../components/CurrentDiscipline.vue'
import store from './store'

var app = new Vue({
  el: '#profile-selection',
  data: { },
  components: {
    'b-current-role': CurrentRole,
    'b-current-unity': CurrentUnity,
    'b-current-school-year': CurrentSchoolYear,
    'b-current-classroom': CurrentClassroom,
    'b-current-teacher': CurrentTeacher,
    'b-current-discipline': CurrentDiscipline
  },
  store: store
})
