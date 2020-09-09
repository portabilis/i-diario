import Vue from 'vue/dist/vue.js'

import ProfileChanger from '../components/ProfileChanger.vue'
import Multiselect from 'vue-multiselect'

import store from './store'

Vue.component('multiselect', Multiselect)

var app = new Vue({
  el: '#profile-selection',
  data: { },
  components: {
    'b-profile-changer': ProfileChanger,
    'multiselect': Multiselect
  },
  store: store
})
