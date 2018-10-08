import _ from 'lodash';
import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import AuctionShow from '../components/auction/show';
import {
  getAllAuctionPayloads,
  getCompanyBarges,
  acceptWinningSolution,
  setPortAgent,
  subscribeToAuctionUpdates,
  submitBargeForApproval,
  unsubmitBargeForApproval,
  approveBarge,
  rejectBarge,
  submitBid,
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
    companyProfile,
    connection: state.auctionsReducer.connection,
    loading: state.auctionsReducer.loading
  }
};

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  formSubmit(auctionId, ev) {
    ev.preventDefault();

    const bidElements = _.reject(ev.target.elements, (e) => !e.dataset.product);
    const bidsByProduct = _.reduce(bidElements, (acc, e) => {
      acc[e.dataset.product] = acc[e.dataset.product] || {};
      acc[e.dataset.product][e.name] = e.value;
      return acc;
    }, {});

    dispatch(submitBid(auctionId, {
      "bids": bidsByProduct,
      "is_traded_bid": elements && elements.is_traded_bid && elements.is_traded_bid.checked
    }));
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
  acceptBid(auctionId, bidIds, ev) {
    ev.preventDefault();

    const elements = ev.target.elements;
    let solutionData = {'comment': '', 'bid_ids': bidIds};
    if(elements.comment) {
      solutionData = {
        'comment': elements.comment.value
      };
    }
    const portAgent = {'port_agent': elements.auction_port_agent.value};

    dispatch(setPortAgent(auctionId, portAgent));
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
      return <AuctionShow {...this.props}/>;
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(AuctionContainer);
