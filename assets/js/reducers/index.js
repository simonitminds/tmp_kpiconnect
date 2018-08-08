import {combineReducers} from "redux";
import auctionsReducer from "./auctions";
import auctionFormReducer from "./auction-form";
import companyProfileReducer from "./company-profile";

export default combineReducers({
  auctionsReducer,
  auctionFormReducer,
  companyProfileReducer,
});
