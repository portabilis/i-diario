export default {
  setSelected({ dispatch, commit, state }, selected) {
    commit('setSelected', selected)

    dispatch('setRequired', null, { root: true })
    dispatch('updateValidation', null, { root: true })

    if (state.fetchAssociation) {
      dispatch(state.fetchAssociation, null, { root: true })
    }
  }
}
