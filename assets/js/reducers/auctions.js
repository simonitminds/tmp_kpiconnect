import _ from "lodash";
import { replaceListItem } from "../utilities";
import { RECEIVE_AUCTIONS, UPDATE_AUCTION_STATE } from "../constants";

const initialState = {
  auctions: [],
  loading: true
};

export default function(state, action) {
  switch(action.type) {
    case RECEIVE_AUCTIONS: {
      if(_.isEmpty(action.auctions)) {
        return state;
      } else {
        return {
          ...state,
          auctions: action.auctions,
          loading: false
        };
      }
    }
    case UPDATE_AUCTION_STATE: {
      const origAuction = _.chain(state.auctions)
            .filter(['id', action.auction.id])
            .first()
            .value();
      let updatedAuction;
      if (action.auction.bid_list) {
        updatedAuction = {...origAuction, state: action.auction.state, bid_list: action.auction.bid_list};
      } else {
        updatedAuction = {...origAuction, state: action.auction.state};
      }
      const newAuctionList = replaceListItem(state.auctions, origAuction, updatedAuction);
      return {
        ...state,
        auctions: newAuctionList,
        loading: false
      };
    }
    default: {
      return state || initialState;
    }
  }
}
