import React from 'react';

export default class BidStatus extends React.Component {
  constructor(props) {
    super(props);
  }

  handleAnimationEnd(event) {
    this.props.updateBidStatus(this.props.auctionPayload.auction.id, {'success': null, 'message': null});
  }

  render() {
    const success = this.props.auctionPayload.success;
    const message = this.props.auctionPayload.message;

    const statusDisplay = () => {
      if (success) {
        return (
          <div
            className="auction-notification auction-notification--flash is-success"
            onAnimationEnd={this.handleAnimationEnd.bind(this)}
          >
            <h3 className="has-text-weight-bold qa-auction-bid-status">{message}</h3>
          </div>
        )
      } else {
        return (
          <div
            className="auction-notification auction-notification--flash is-danger"
            onAnimationEnd={this.handleAnimationEnd.bind(this)}
          >
            <h3 className="has-text-weight-bold qa-auction-bid-status">{message}</h3>
          </div>
        )
      }
    };

    return(
      <div className="auction-notification__container">
        {statusDisplay()}
      </div>
    );
  };
}
