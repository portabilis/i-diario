import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'

const disciplines = {
  namespaced: true,
  state: {
    selected: null,
    options: [],
    required: false,
    isLoading: true,
  },
  mutations,
  getters: {
    ...getters,
    isSelected: function(state) {
      return !!(state.selected && (state.selected.knowledge_area_id || state.selected.discipline_id))
    },
    getByKnowledgeAreaId: (state) => (id) => {
      if(!state.options) {
        return null
      }
      return state.options.find(option => option && option.knowledge_area_id == id)
    },
    getByDisciplineId: (state) => (id) => {
      if(!state.options) {
        return null
      }
      return state.options.find(option => option && option.discipline_id == id)
    }
  },
  actions: {
    preLoad({commit, getters}) {
      commit('setOptions', window.state.available_disciplines)

      if (window.state.current_knowledge_area_id) {
        commit('setSelected', getters.getByKnowledgeAreaId(window.state.current_knowledge_area_id))
      } else if (window.state.current_discipline_id) {
        commit('setSelected', getters.getByDisciplineId(window.state.current_discipline_id))
      }

      commit('setIsLoading', false)
    },
    fetch({ dispatch, state, commit, rootState, rootGetters }) {
      commit('setIsLoading', true)
      commit('setOptions', [])
      commit('setSelected', null)

      const filters = {
        teacher_id: rootState.teachers.selected.id,
        classroom_id: rootState.classrooms.selected.id,
      }

      const route = Routes.search_grouped_by_knowledge_area_disciplines_pt_br_path({
        filter: filters,
        format: 'json'
      })

      console.log(route)

      axios.get(route)
        .then(response => {
          commit('setOptions', response.data.disciplines)

          if(response.data.disciplines.length === 1) {
            commit('setSelected', response.data.disciplines[0])
          }

          commit('setIsLoading', false)
        })
    }
  }
}

export default disciplines
