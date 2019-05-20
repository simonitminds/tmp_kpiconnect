import _ from 'lodash';
import {
  RECEIVE_FIXTURE_PAYLOADS,
} from '../constants';

const initialState = {
  auctionFixtures: [],
  connection: false,
  loading: true
}

let newFixturePayloadList;
let updatedFixturePayload;

export default function(state, action) {
  switch(action.type) {
    case RECEIVE_FIXTURE_PAYLOADS: {
      return {
        ...state,
        fixturePayloads: action.fixturePayloads,
        loading: false
      };
    }
    default: {
      return state || initialState;
    }
  }
}
