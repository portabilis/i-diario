import Vue from 'vue/dist/vue.js'

import ProfileChanger from '../components/ProfileChanger.vue'
import Multiselect from 'vue-multiselect'

Vue.component('multiselect', Multiselect)

new Vue({
  el: '#profile-selection',
  data: { },
  components: {
    'b-profile-changer': ProfileChanger,
    'multiselect': Multiselect
  }
})
