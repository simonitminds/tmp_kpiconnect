import _ from "lodash";
import {
  RECEIVE_COMPANY_BARGES
} from "../constants";

const initialState = {
  barges: []
};

export default function(state, action) {
  switch(action.type) {
    case RECEIVE_COMPANY_BARGES: {
      return {
        ...state,
        barges: action.barges,
        loading: false
      };
    }
    default: {
      return state || initialState;
    }
  }
}
