import _ from "lodash";
import { RECEIVE_AUCTIONS } from "../constants/auctions";

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
    default: {
      return state || initialState;
    }
  }
}
