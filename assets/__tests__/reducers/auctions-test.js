import _ from "lodash";
import auctionsReducer, {
  initialState
} from '../../js/reducers/auctions';
import {
  RECEIVE_AUCTION_PAYLOADS,
  UPDATE_AUCTION_PAYLOAD
} from '../../js/constants';


describe('receive_auctions', ()=> {
  test('overwrites existing', ()=> {
    const state = Object.assign({}, initialState, {
      auctions: [{ id: 1 }, { id: 2 }]
    });
    const action = {
      type: RECEIVE_AUCTION_PAYLOADS,
      auctions: [{ id: 3 }, { id: 4 }]
    }

    const output = auctionsReducer(state, action);

    expect(output.auctions.length).toEqual(2);
    expect(output.auctions[0].id).toEqual(3);
  });
  test('if no auctions received, state is maintained', ()=> {
    const state = Object.assign({}, initialState, {
      auctions: [{ id: 1 }, { id: 2 }]
    });
    const action = {
      type: RECEIVE_AUCTION_PAYLOADS,
      auctions: []
    }

    const output = auctionsReducer(state, action);

    expect(output.auctions.length).toEqual(2);
    expect(output.auctions[0].id).toEqual(1);
  });
});

describe('update_auction_state', ()=> {
  test('replaces auction from list with updated auction', ()=> {
    const state = Object.assign({}, initialState, {
      auctions: [
        {
          id: 1,
          state: { status: "open" },
          bid_list: []
        }, {
          id: 2,
          state: { status: "pending" }
        }
      ]
    });
    const action = {
      type: UPDATE_AUCTION_PAYLOAD,
      auction: {
        id: 2,
        state: { status: "open" },
        bid_list: [{ id: "first bid" }]
      }
    }

    const output = auctionsReducer(state, action);

    expect(output.auctions.length).toEqual(2);
    const target_auction = _.chain(output.auctions)
      .filter(['id', action.auction.id])
      .first()
      .value();
    expect(target_auction).toEqual(action.auction);
  });
});
