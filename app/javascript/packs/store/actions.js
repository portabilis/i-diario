export default {
  setSelected({ dispatch, commit, state }, selected) {
    commit('setSelected', selected)

    dispatch('setRequired', null, { root: true }).then(() => {
      dispatch('updateValidation', null, { root: true }).then(() => {
        if (state.fetchAssociation) {
          dispatch(state.fetchAssociation, null, { root: true })
        }
      })
    })
  }
}
