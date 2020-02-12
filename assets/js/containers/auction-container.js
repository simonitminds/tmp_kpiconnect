import _ from 'lodash';
import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import AuctionShow from '../components/auction/show';
import {
  getAuctionPayload,
  getCompanyBarges,
  acceptWinningSolution,
  subscribeToAuctionUpdates,
  submitBargeForApproval,
  unsubmitBargeForApproval,
  approveBarge,
  rejectBarge,
  submitBid,
  revokeBid,
  removeCOQ,
  submitCOQ,
  submitComment,
  unsubmitComment,
  updateBidStatus,
  inviteObserverToAuction,
  uninviteObserverFromAuction
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
  formSubmit(auctionId, formData) {
    dispatch(submitBid(auctionId, formData));
  },
  addCOQ(auctionId, supplierId, fuelId, spec, delivered, fixtureId) {
    dispatch(submitCOQ(auctionId, supplierId, fuelId, spec, delivered, fixtureId));
  },
  deleteCOQ(coqId) {
    dispatch(removeCOQ(coqId));
  },
  addCommentToSolution(auctionId, formData) {
    dispatch(submitComment(auctionId, formData));
  },
  removeCommentFromSolution(auctionId, commentId) {
    dispatch(unsubmitComment(auctionId, commentId))
  },
  revokeSupplierBid(auctionId, productId, bidSupplierId) {
    dispatch(revokeBid(auctionId, { "product": productId, "supplier": bidSupplierId }));
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
  inviteObserver(auctionId, userId, ev) {
    ev.preventDefault();
    dispatch(inviteObserverToAuction(auctionId, userId))
  },
  uninviteObserver(auctionId, userId, ev) {
    ev.preventDefault();
    dispatch(uninviteObserverFromAuction(auctionId, userId))
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
    this.props.dispatch(subscribeToAuctionUpdates(() => getAuctionPayload(window.auctionId)));
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
      return <AuctionShow {...this.props} />
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(AuctionContainer);
