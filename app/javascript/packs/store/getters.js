export default {
  isValid: function(state, getters) {
    return !state.required || getters.isSelected
  },
  isSelected: function(state) {
    return !!(state.selected && state.selected.id)
  },
  getById: (state) => (id) => {
    return state.options.find(option => option.id == id)
  }
}
