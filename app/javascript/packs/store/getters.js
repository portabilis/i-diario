export default {
  isValid: function(state, getters) {
    return !state.required || getters.isSelected
  },
  isSelected: function(state) {
    return !!(state.selected && state.selected.id)
  },
  getById: (state) => (id) => {
    if(!state.options) {
      return null
    }
    return state.options.find(option => option && option.id == id)
  }
}
