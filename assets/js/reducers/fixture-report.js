import {
  RECEIVE_FIXTURE_EVENT_PAYLOAD
} from '../constants';

const initialState = {
  eventPayload: [],
  connection: false,
  loading: true
}

export default function(state, action) {
  switch (action.type) {
    case RECEIVE_FIXTURE_EVENT_PAYLOAD: {
      return {
        ...state,
        fixtureEventPayload: action.fixtureEventPayload,
        loading: false
      }
    }
    default: {
      return state || initialState;
    }
  }
}
