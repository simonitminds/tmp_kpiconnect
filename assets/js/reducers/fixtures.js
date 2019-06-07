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
      const newFixtures = _
        .chain(state.fixturePayloads)
        .flatMap((payload) => payload.fixtures)
        .keyBy((fixture) => fixture.id)
        .assign({[deliveredFixture.id]: deliveredFixture})
        .toPairs()
        .map(([_key, fixture]) => fixture)
        .value();

      const fixturePayloads = _
        .chain(state.fixturePayloads)
        .map((payload) => {
          return _.set(
            payload,
            'fixtures',
            _.intersectionBy(payload.fixtures, newFixtures, 'id'));
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
