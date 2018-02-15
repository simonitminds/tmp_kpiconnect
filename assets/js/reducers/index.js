import {combineReducers} from "redux";
import auctionsReducer from "./auctions";
import auctionFormReducer from "./auction-form";
export default combineReducers({auctionsReducer, auctionFormReducer});
