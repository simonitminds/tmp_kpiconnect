import {combineReducers} from "redux";
import auctionsReducer from "./auctions";
import auctionFormReducer from "./auction-form";
import companyProfileReducer from "./company-profile";
import impersonationReducer from "./impersonation";

export default combineReducers({
  auctionsReducer,
  auctionFormReducer,
  companyProfileReducer,
  impersonationReducer
});
