import {combineReducers} from "redux";
import auctionsReducer from "./auctions";
import historicalAuctionsReducer from "./historical-auctions";
import fixturesReducer from './fixtures'
import auctionFormReducer from "./auction-form";
import companyProfileReducer from "./company-profile";
import messagesReducer from "./messages";

export default combineReducers({
  auctionsReducer,
  historicalAuctionsReducer,
  fixturesReducer,
  auctionFormReducer,
  companyProfileReducer,
  messagesReducer
});
