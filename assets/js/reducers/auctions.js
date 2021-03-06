import _ from "lodash";
import { replaceListItem } from "../utilities";
import {
  AUCTION_CHANNEL_CONNECTED,
  AUCTION_CHANNEL_DISCONNECTED,
  RECEIVE_AUCTION_PAYLOADS,
  REMOVE_AUCTION,
  UPDATE_AUCTION_PAYLOAD,
  UPDATE_BID_STATUS,
} from "../constants";

const initialState = {
  auctionPayloads: [],
  connection: false,
  loading: true
};

let newAuctionPayloadList;
let updatedAuctionPayload;

export default function(state, action) {
  switch(action.type) {
    case RECEIVE_AUCTION_PAYLOADS: {
      return {
        ...state,
        auctionPayloads: action.auctionPayloads,
        loading: false
      };
    }
    case REMOVE_AUCTION: {
      const origAuctionPayload = _.chain(state.auctionPayloads)
            .filter(['auction.id', action.auctionId.id])
            .first()
            .value();
      return {
        ...state,
        auctionPayloads: _.without(state.auctionPayloads,¬†origAuctionPayload),
        loading: false
      };
    }
    case UPDATE_AUCTION_PAYLOAD: {
      const origAuctionPayload = _.chain(state.auctionPayloads)
            .filter(['auction.id', action.auctionPayload.auction.id])
            .first()
            .value();
      if (origAuctionPayload) {
        updatedAuctionPayload = {
          ...action.auctionPayload,
          success: origAuctionPayload.success,
          message: origAuctionPayload.message
        };
        newAuctionPayloadList = replaceListItem(
          state.auctionPayloads,
          origAuctionPayload,
          updatedAuctionPayload
        );
      } else {
        newAuctionPayloadList = _.concat(state.auctionPayloads, action.auctionPayload);
      }

      return {
        ...state,
        auctionPayloads: newAuctionPayloadList,
        loading: false
      };
    }
    case UPDATE_BID_STATUS: {
      const origAuctionPayload = _.chain(state.auctionPayloads)
            .filter(['auction.id', action.auctionId])
            .first()
            .value();
      const updatedAuctionPayload = {
        ...origAuctionPayload,
        success: action.success,
        message: action.message
      }
      newAuctionPayloadList = replaceListItem(
        state.auctionPayloads,
        origAuctionPayload,
        updatedAuctionPayload
      );
      return {
        ...state,
        auctionPayloads: newAuctionPayloadList,
        loading: false
      };
    }
    case AUCTION_CHANNEL_CONNECTED: {
      return {
        ...state,
        connection: true
      };
    }
    case AUCTION_CHANNEL_DISCONNECTED: {
      return {
        ...state,
        connection: false
      };
    }
    default: {
      return state || initialState;
    }
  }
}
