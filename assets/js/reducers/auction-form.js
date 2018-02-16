import _ from "lodash";
import moment from 'moment';
import { replaceListItem } from "../utilities";
import { RECIEVE_AUCTION_FORM_DATA, UPDATE_DATE, UPDATE_INFORMATION } from "../constants";

const initialState = {
  auction: null,
  auction_start_date: null,
  auction_start_time: null,
  eta_date: null,
  eta_time: null,
  etd_date: null,
  etd_time: null,
  fuels: null,
  ports: null,
  vessels: null,
  loading: true
};

const setUTCDateTime = (dateTime) => {
  if (dateTime) {
    return moment(dateTime).utc();
  } else {
    return moment().utc();
  }
}

export default function(state, action) {
  switch(action.type) {
    case RECIEVE_AUCTION_FORM_DATA: {
      if(_.isEmpty(action.data)) {
        return state;
      } else {
        return {
          ...state,
          auction: action.data.auction,
          auction_start_date: setUTCDateTime(action.data.auction.auction_start),
          auction_start_time: setUTCDateTime(action.data.auction.auction_start),
          eta_date: setUTCDateTime(action.data.auction.eta),
          eta_time: setUTCDateTime(action.data.auction.eta),
          etd_date: setUTCDateTime(action.data.auction.etd),
          etd_time: setUTCDateTime(action.data.auction.etd),
          fuels: action.data.fuels,
          ports: action.data.ports,
          vessels: action.data.vessels,
          loading: false
        };
      }
    }
    case UPDATE_INFORMATION: {
      const property = action.data.property;
      const split_property = _.split(property, '.');
      if (split_property.length === 2) {
        return {...state, [split_property[0]]: {...state[split_property[0]], [split_property[1]]: action.data.value}}
      } else {
        return { ...state,
          [property]: action.data.value,
        };
      }
    }
    case UPDATE_DATE: {
      const auctionProperty = action.data.property.slice(0, -5);
      let value = action.data.value;
      if (action.data.property.slice(-5) === "_date") {
        const accurate_time = moment(state.auction[auctionProperty]).utc();
        const hours = accurate_time.hour();
        const mins = accurate_time.minutes();
        value = value.hour(hours);
        value = value.minutes(mins);
      }
      return { ...state,
        [auctionProperty + "_date"]: value,
        [auctionProperty + "_time"]: value,
        auction: { ...state.auction, [auctionProperty]: value}
      }
    }
    default: {
      return state || initialState;
    }
  }
}