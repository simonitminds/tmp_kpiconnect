import _ from 'lodash';
import {
  RECEIVE_FIXTURE_PAYLOADS,
  RECEIVE_DELIVERED_FIXTURE
} from '../constants';

const initialState = {
  fixturePayloads: [],
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
    case RECEIVE_DELIVERED_FIXTURE: {
      const deliveredFixture = _.get(action, 'deliveredFixture');
      const fixturePayloads = _
        .chain(state.fixturePayloads)
        .map((payload) => {
          return _.set(
            payload,
            'fixtures',
            _.unionBy(payload.fixtures, [deliveredFixture], 'id'));
        })
        .value();

      return {
        ...state,
        fixturePayloads,
        loading: false
      }
    }
    default: {
      return state || initialState;
    }
  }
}
