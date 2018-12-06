import _ from 'lodash';
import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import AuctionShow from '../components/auction/show';
import {
  getCompanyBarges,
  acceptWinningSolution,
  setPortAgent,
  subscribeToAuctionUpdates,
  submitBargeForApproval,
  unsubmitBargeForApproval,
  approveBarge,
  rejectBarge,
  submitBid,
  revokeBid,
  updateBidStatus
} from '../actions';

const mapStateToProps = (state) => {
  const auctionPayload = _.chain(state.auctionsReducer.auctionPayloads)
    .filter(['auction.id', window.auctionId])
    .first()
    .value();

  const companyProfile = {
    companyBarges: state.companyProfileReducer.barges
  };

  return {
    auctionPayload,
    auctionPayloads: state.auctionsReducer.auctionPayloads,
    companyProfile,
    connection: state.auctionsReducer.connection,
    loading: state.auctionsReducer.loading
  }
};

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  formSubmit(auctionId, ev) {
    const bidElements = _.reject(ev.target.elements, (e) => !e.dataset.fuelInput);
    const vesselFuelBoxes = _.reject(ev.target.elements, (e) => !e.dataset.vesselFuel);

    const fuelBids = _.reduce(bidElements, (acc, e) => {
      acc[e.dataset.fuel] = acc[e.dataset.fuel] || {};
      switch(e.type) {
        case 'checkbox':
          acc[e.dataset.fuel][e.name] = e.checked;
          break;

        default:
          acc[e.dataset.fuel][e.name] = e.value;
          break;
      }
      return acc;
    }, {});

    const bidsByProduct = _.reduce(vesselFuelBoxes, (acc, vfBox) => {
      const {vesselFuel, fuel} = vfBox.dataset;
      if(vfBox.checked) {
        acc[vesselFuel] = { ...fuelBids[fuel] };
      }
      return acc;
    }, {});

    const elements = ev.target.elements;
    _.forEach(elements, (e) => e.value = "");

    dispatch(submitBid(auctionId, {
      "bids": bidsByProduct,
      "is_traded_bid": elements && elements.is_traded_bid && elements.is_traded_bid.checked
    }));
  },
  revokeSupplierBid(auctionId, productId) {
    dispatch(revokeBid(auctionId, { "product": productId }));
  },
  submitBargeForm(auctionId, bargeId, ev) {
    ev.preventDefault();
    dispatch(submitBargeForApproval(auctionId, bargeId));
  },
  unsubmitBargeForm(auctionId, bargeId, ev) {
    ev.preventDefault();
    dispatch(unsubmitBargeForApproval(auctionId, bargeId));
  },
  approveBargeForm(auctionId, bargeId, supplierId, ev) {
    ev.preventDefault();
    dispatch(approveBarge(auctionId, bargeId, supplierId));
  },
  rejectBargeForm(auctionId, bargeId, supplierId, ev) {
    ev.preventDefault();
    dispatch(rejectBarge(auctionId, bargeId, supplierId));
  },
  acceptSolution(auctionId, bidIds, ev) {
    ev.preventDefault();

    const elements = ev.target.elements;
    let solutionData = {
      'comment': elements.comment ? elements.comment.value : '',
      'bid_ids': bidIds,
      'port_agent': elements.auction_port_agent ? elements.auction_port_agent.value : ''
    };

    dispatch(acceptWinningSolution(auctionId, solutionData));
  },
  ...bindActionCreators({ updateBidStatus }, dispatch)
});


export class AuctionContainer extends React.Component {
  dispatchItem() {
    this.props.dispatch(subscribeToAuctionUpdates());
    this.props.dispatch(getCompanyBarges(window.companyId));
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
      return <div className="alert is-info">Loading...</div>
    } else {
      return <AuctionShow {...this.props}/>
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(AuctionContainer);
