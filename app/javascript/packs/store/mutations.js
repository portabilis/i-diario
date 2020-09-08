export default {
  setRequired(state, required) {
    state.required = required
  },
  set_selected(state, id) {
    state.selected = id
    state.isValid = !state.required || !!state.selected
  },
  set_options(state, unities) {
    state.options = unities
  }
}
