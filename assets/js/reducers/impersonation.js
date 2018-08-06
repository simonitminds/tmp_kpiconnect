import _ from "lodash";
import {
  RECEIVE_IMPERSONATION
} from "../constants";

const initialState = {
  impersonating: null,
  impersonatedBy: null,
};

export default function(state, action) {
  switch(action.type) {
    case RECEIVE_IMPERSONATION: {
      return{
        ...state,
        impersonating: action.impersonating,
        impersonatedBy: action.impersonated_by
      };
    }
    default: {
      return state || initialState;
    }
  }
}
