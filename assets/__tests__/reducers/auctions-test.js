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
      auctionPayloads: [
        { auction: { id: 1 }},
        { auction: { id: 2 }}
      ]
    });
    const action = {
      type: RECEIVE_AUCTION_PAYLOADS,
      auctionPayloads: [
        { auction: { id: 3 }},
        { auction: { id: 4 }}
      ]
    }

    const output = auctionsReducer(state, action);

    expect(output.auctionPayloads.length).toEqual(2);
    expect(output.auctionPayloads[0].auction.id).toEqual(3);
  });
  test('if no auctions received, state is maintained', ()=> {
    const state = Object.assign({}, initialState, {
      auctionPayloads: [
        { auction: { id: 1 }},
        { auction: { id: 2 }}
      ]
    });
    const action = {
      type: RECEIVE_AUCTION_PAYLOADS,
      auctionPayloads: []
    }

    const output = auctionsReducer(state, action);

    expect(output.auctionPayloads.length).toEqual(2);
    expect(output.auctionPayloads[0].auction.id).toEqual(1);
  });
});

describe('update_auction_state', ()=> {
  test('replaces auction from list with updated auction', ()=> {
    const state = Object.assign({}, initialState, {
      auctionPayloads: [
        {
          auction: { id: 1 },
          state: { status: "open" },
          bid_list: []
        }, {
          auction: { id: 2 },
          state: { status: "pending" },
          bid_list: []
        }
      ]
    });
    const action = {
      type: UPDATE_AUCTION_PAYLOAD,
      auctionPayload: {
        auction: { id: 2 },
        state: { status: "open" },
        bid_list: [{ id: "first bid" }]
      }
    }

    const output = auctionsReducer(state, action);

    expect(output.auctionPayloads.length).toEqual(2);
    const targetAuction = _.chain(output.auctionPayloads)
      .filter(['auction.id', action.auctionPayload.auction.id])
      .first()
      .value();
    expect(targetAuction).toEqual(action.auctionPayload);
  });
});
