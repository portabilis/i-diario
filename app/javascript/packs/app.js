import Vue from 'vue/dist/vue.js'

import ProfileChanger from '../components/ProfileChanger.vue'
import store from './store'

var app = new Vue({
  el: '#profile-selection',
  data: { },
  components: {
    'b-profile-changer': ProfileChanger
  },
  store: store
})
