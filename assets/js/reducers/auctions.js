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
      console.log(action);
      const origAuction = _.chain(state.auctions)
            .filter(['id', action.auction.id])
            .first()
            .value();
      const updatedAuction = {...origAuction, state: action.auction.state};
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
