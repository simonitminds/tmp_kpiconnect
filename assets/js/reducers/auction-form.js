import _ from "lodash";
import moment from 'moment';
import { replaceListItem } from "../utilities";
import { RECEIVE_AUCTION_FORM_DATA,
         UPDATE_DATE,
         UPDATE_INFORMATION,
         RECEIVE_SUPPLIERS,
         SELECT_ALL_SUPPLIERS,
         TOGGLE_SUPPLIER,
         DESELECT_ALL_SUPPLIERS,
 } from "../constants";

const initialState = {
  auction: null,
  scheduled_start_date: null,
  scheduled_start_time: null,
  eta_date: null,
  eta_time: null,
  etd_date: null,
  etd_time: null,
  suppliers: null,
  fuels: null,
  ports: null,
  vessels: null,
  loading: true,
  selectedPort: null,
  selectedSuppliers: []
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
          scheduled_start_date: setUTCDateTime(action.data.auction.scheduled_start),
          scheduled_start_time: setUTCDateTime(action.data.auction.scheduled_start),
          eta_date: setUTCDateTime(action.data.auction.eta),
          eta_time: setUTCDateTime(action.data.auction.eta),
          etd_date: setUTCDateTime(action.data.auction.etd),
          etd_time: setUTCDateTime(action.data.auction.etd),
          selectedPort: _.get(action, 'data.auction.port.id'),
          selectedSuppliers: supplierList,
          suppliers: _.get(action, 'data.suppliers', []),
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
        return {...state, [split_property[0]]: {...state[split_property[0]], [split_property[1]]: action.data.value}};
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
