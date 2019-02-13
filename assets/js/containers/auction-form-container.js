import _ from 'lodash';
import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import Form from '../components/auction/form';
import { receiveAuctionFormData,
         updateDate,
         updateInformation,
         updateInformationFromCheckbox,
         selectAuctionType,
         toggleSupplier,
         selectAllSuppliers,
         deselectAllSuppliers,
         setPort,
         selectPort } from '../actions';

const mapStateToProps = (state, props) => {
  return {
    auction: state.auctionFormReducer.auction || props.auction,
    errors: state.auctionFormReducer.errors || props.errors || {},
    type: state.auctionFormReducer.type || props.type || 'spot',
    scheduled_start_date: state.auctionFormReducer.scheduled_start_date,
    scheduled_start_time: state.auctionFormReducer.scheduled_start_time,
    eta_date: state.auctionFormReducer.eta_date,
    eta_time: state.auctionFormReducer.eta_time,
    etd_date: state.auctionFormReducer.etd_date,
    etd_time: state.auctionFormReducer.etd_time,
    suppliers: state.auctionFormReducer.suppliers || props.suppliers,
    fuels: state.auctionFormReducer.fuels || props.fuels,
    ports: state.auctionFormReducer.ports || props.ports,
    vessels: state.auctionFormReducer.vessels || props.vessels,
    credit_margin_amount: state.auctionFormReducer.credit_margin_amount || props.credit_margin_amount,
    is_traded_bid_allowed: state.auctionFormReducer.is_traded_bid_allowed || props.is_traded_bid_allowed,
    loading: state.auctionFormReducer.loading,
    selectedSuppliers: state.auctionFormReducer.selectedSuppliers
  };
};

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  ...bindActionCreators({ updateDate,
                          updateInformation,
                          updateInformationFromCheckbox,
                          selectAuctionType,
                          toggleSupplier,
                          selectAllSuppliers,
                          deselectAllSuppliers,
                          selectPort }, dispatch)
});

export class AuctionFormContainer extends React.Component {
  dispatchItem() {
    this.props.dispatch(receiveAuctionFormData(this.props.auction, this.props.suppliers, this.props.fuels, this.props.ports, this.props.vessels, this.props.credit_margin_amount));
  }
  componentDidMount() {
    this.dispatchItem();
  }
  componentDidUpdate(prevProps) {
    if (this.props.id !== prevProps.id) {
      this.dispatchItem();
    }
  }
  render() {
      if (this.props.loading) {
      return <div className="alert is-info">Loading...</div>;
    } else {
      return <Form {...this.props} />;
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(AuctionFormContainer);
