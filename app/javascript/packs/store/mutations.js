import defaultState from './state.js'

export default {
  setRequired(state, required) {
    state.required = required
  },
  setSelected(state, selected) {
    state.selected = selected
  },
  setOptions(state, unities) {
    state.options = unities
  },
  setIsLoading(state, value) {
    state.isLoading = value
  },
  resetState(state) {
    Object.assign(state, defaultState)
  }
}
