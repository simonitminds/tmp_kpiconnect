import _ from "lodash";
import { replaceListItem } from "../utilities";
import { RECEIVE_AUCTIONS, UPDATE_AUCTION_STATE } from "../constants/auctions";

const initialState = {
  auctions: []
};

export default function(state, action) {
  switch(action.type) {
    case RECEIVE_AUCTIONS: {
      if(_.isEmpty(action.auctions)) {
        return state;
      } else {
        return {...state, auctions: action.auctions};
      }
    }
    case UPDATE_AUCTION_STATE: {
      const origAuction = _.chain(state.auctions)
            .filter(['id', action.auction.id])
            .first()
            .value();
      const updatedAuction = {...origAuction, state: action.auction.state};
      const newAuctionList = replaceListItem(state.auctions, origAuction, updatedAuction);
      return {...state, auctions: newAuctionList};
    }
    default: {
      return state || initialState;
    }
  }
}
