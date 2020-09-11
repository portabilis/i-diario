import axios from 'axios'

import mutations from '../mutations.js'
import getters from '../getters.js'

const knowledge_area_disciplines = {
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
      commit('setOptions', window.state.available_knowledge_area_disciplines)

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

      const route = Routes.search_with_disciplines_knowledge_areas_pt_br_path({
        filter: filters,
        format: 'json'
      })

      axios.get(route)
        .then(response => {
          commit('setOptions', response.data.knowledge_areas)

          if(response.data.knowledge_areas.length === 1) {
            commit('setSelected', response.data.knowledge_areas[0])
          }

          commit('setIsLoading', false)
        })
    }
  }
}

export default knowledge_area_disciplines
