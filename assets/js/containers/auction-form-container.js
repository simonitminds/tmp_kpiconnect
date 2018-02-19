import _ from 'lodash';
import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import AuctionForm from '../components/auction/AuctionForm';
import { receiveAuctionFormData,
         updateDate,
         updateInformation,
         toggleSupplier,
         selectAllSuppliers,
         deselectAllSuppliers,
         setPort,
         selectPort } from '../actions';

const mapStateToProps = (state, props) => {
  return {
    auction: state.auctionFormReducer.auction || props.auction,
    auction_start_date: state.auctionFormReducer.auction_start_date,
    auction_start_time: state.auctionFormReducer.auction_start_time,
    eta_date: state.auctionFormReducer.eta_date,
    eta_time: state.auctionFormReducer.eta_time,
    etd_date: state.auctionFormReducer.etd_date,
    etd_time: state.auctionFormReducer.etd_time,
    fuels: state.auctionFormReducer.fuels || props.fuels,
    ports: state.auctionFormReducer.ports || props.ports,
    vessels: state.auctionFormReducer.vessels || props.vessels,
    loading: state.auctionFormReducer.loading,
    suppliers: state.auctionFormReducer.suppliers,
    selectedSuppliers: state.auctionFormReducer.selectedSuppliers
  };
};

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  ...bindActionCreators({ updateDate,
                          updateInformation,
                          toggleSupplier,
                          selectAllSuppliers,
                          deselectAllSuppliers,
                          selectPort }, dispatch)
});

export class AuctionFormContainer extends React.Component {
  dispatchItem() {
    this.props.dispatch(receiveAuctionFormData(this.props.auction, this.props.fuels, this.props.ports, this.props.vessels));
    if(this.props.auction.port) {
      this.props.dispatch(setPort(this.props.auction.port.id));
    }
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
      return <div>Loading...</div>
    } else {
      return <AuctionForm {...this.props} />;
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(AuctionFormContainer);
