import _ from "lodash";
import moment from 'moment';
import { replaceListItem,
         formatPrice
 } from "../utilities";
import dotProp from 'dot-prop-immutable';
import { RECEIVE_AUCTION_FORM_DATA,
         UPDATE_DATE,
         UPDATE_MONTH,
         UPDATE_INFORMATION,
         RECEIVE_SUPPLIERS,
         SELECT_ALL_SUPPLIERS,
         SELECT_AUCTION_TYPE,
         TOGGLE_SUPPLIER,
         DESELECT_ALL_SUPPLIERS,
 } from "../constants";

const initialState = {
  auction: null,
  errors: null,
  eta_date: null,
  eta_time: null,
  etd_date: null,
  etd_time: null,
  fuels: null,
  fuel_indexes: null,
  current_index_price: null,
  fuel_quantity: null,
  loading: true,
  ports: null,
  start_date: null,
  end_date: null,
  fuel_quantity: null,
  total_fuel_volume: null,
  show_total_fuel_volume: null,
  scheduled_start_date: null,
  scheduled_start_time: null,
  selectedPort: null,
  selectedSuppliers: [],
  start_date: null,
  end_date: null,
  type: null,
  suppliers: null,
  vessels: null,
  credit_margin_amount: null,
  is_traded_bid_allowed: null
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
    case RECEIVE_AUCTION_FORM_DATA: {
      if(_.isEmpty(action.data)) {
        return state;
      } else {
        const supplierList = _.map(action.data.auction.suppliers, 'id');
        return {
          ...state,
          auction: action.data.auction,
          errors: action.data.errors,
          credit_margin_amount: formatPrice(action.data.credit_margin_amount),
          is_traded_bid_allowed: _.get(action, 'data.auction.is_traded_bid_allowed'),
          eta_date: setUTCDateTime(action.data.auction.eta),
          eta_time: setUTCDateTime(action.data.auction.eta),
          etd_date: setUTCDateTime(action.data.auction.etd),
          etd_time: setUTCDateTime(action.data.auction.etd),
          fuels: action.data.fuels,
          fuel_indexes: action.data.fuel_indexes,
          current_index_price: _.get(action, 'data.auction.current_index_price', 0),
          loading: false,
          ports: action.data.ports,
          scheduled_start_date: setUTCDateTime(action.data.auction.scheduled_start),
          scheduled_start_time: setUTCDateTime(action.data.auction.scheduled_start),
          selectedPort: _.get(action, 'data.auction.port.id'),
          selectedSuppliers: supplierList,
          start_date: setUTCDateTime(action.data.auction.start_date),
          end_date: setUTCDateTime(action.data.auction.end_date),
          type: _.get(action, 'data.auction.type'),
          suppliers: _.get(action, 'data.suppliers', []),
          vessels: action.data.vessels,
        };
      }
    }
    case UPDATE_INFORMATION: {
      return dotProp.set(state, action.data.property, action.data.value);
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
      };
    }
    case UPDATE_MONTH: {
      const startDate = state.auction.start_date;
      const endDate = state.auction.end_date;
      let auctionProperty = action.data.property.slice(0, -5);
      let value = action.data.value;
      switch(auctionProperty) {
        case 'start_date': {
          if (!!endDate && moment(value).isAfter(endDate)) {
            auctionProperty = 'end_date';
          }
        }
        case 'end_date': {
          if (!!startDate && moment(value).isBefore(startDate) > 0) {
            auctionProperty = 'start_date';
          }
        }
      }
      return { ...state,
        [auctionProperty + "_date"]: value,
        auction: { ...state.auction, [auctionProperty]: value}
      };
    }
    case RECEIVE_SUPPLIERS: {
      const port_id = parseInt(action.port);
      const suppliers = action.suppliers;
      return {
        ...state, auction: {...state.auction, port_id: port_id},
        suppliers: suppliers, selectedPort: port_id, selectedSuppliers: []};
    }
    case TOGGLE_SUPPLIER: {
      const supplier_id = action.data.supplier_id;
      let newList;

      if(_.includes(state.selectedSuppliers, supplier_id)) {
        newList = replaceListItem(state.selectedSuppliers, supplier_id, null);
      } else {
        newList = [...state.selectedSuppliers, supplier_id];
      }
      return {...state, selectedSuppliers: newList};
    }
    case SELECT_AUCTION_TYPE: {
      const auctionType = action.data.type;

      return {...state, type: auctionType};
    }
    case SELECT_ALL_SUPPLIERS: {
      if(state.suppliers) {
        return {...state, selectedSuppliers: _.map(state.suppliers, 'id')};
      } else {
        return state;
      }
    }
    case DESELECT_ALL_SUPPLIERS: {
      return {...state, selectedSuppliers: []};
    }
    default: {
      return state || initialState;
    }
  }
}
