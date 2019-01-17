import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { cardDateFormat, formatTimeRemaining, formatTimeRemainingColor, timeRemainingCountdown } from '../../utilities';
import ServerDate from '../../serverdate';

class AuctionTimeRemaining extends React.Component {
  constructor(props) {
    super(props);
    const { auctionPayload } = props;
    const serverTime = moment(ServerDate.now()).utc();
    this.state = {
      timeRemaining: timeRemainingCountdown(auctionPayload, serverTime)
    }
  }

  componentDidMount() {
    this.timerID = setInterval(
      () => this.tick(),
      500
    );
  }

  componentWillUnmount() {
    clearInterval(this.timerID);
  }

  tick() {
    const time = moment(ServerDate.now()).utc();
    const { auctionPayload } = this.props;
    this.setState({
      timeRemaining: timeRemainingCountdown(auctionPayload, time)
    });
  }


  render() {
    const { auctionPayload } = this.props;
    const { timeRemaining } = this.state;
    const auctionStatus = _.get(auctionPayload, 'status');
    const auctionStartTime = _.get(auctionPayload, 'auction.scheduled_start');
    const auctionEndTime = _.get(auctionPayload, 'auction.auction_ended');
    const auctionClosedTime = _.get(auctionPayload, 'auction.auction_closed_time');

    if (auctionStatus == "open" || auctionStatus == "decision") {
      return (
        <span className={`auction-card__time-remaining auction-card__time-remaining--${formatTimeRemainingColor(auctionStatus, timeRemaining)}`}>
          <span className="icon has-margin-right-xs"><FontAwesomeIcon icon={["far", "clock"]} /></span>
          <span className="qa-auction-time_remaining" id="time-remaining">
            {formatTimeRemaining(auctionStatus, timeRemaining, "index")}
          </span>
        </span>
      );
    } else if (auctionStatus == "draft") {
      return (
        <span className="auction-card__time-remaining auction-card__time-remaining--inactive">
          <span className="icon has-margin-right-xs"><FontAwesomeIcon icon={["far", "clock"]} /></span>
          Not Scheduled
        </span>
      );
    } else if (auctionStatus == "pending") {
      return (
        <span className="auction-card__time-remaining auction-card__time-remaining--inactive">
          <span className="icon has-margin-right-xs"><FontAwesomeIcon icon={["far", "clock"]} /></span>
          {cardDateFormat(auctionStartTime)}
        </span>
      );
    } else if (auctionStatus == "canceled") {
      return (
        <span className="auction-card__time-remaining auction-card__time-remaining--inactive">
          <span className="icon has-margin-right-xs"><FontAwesomeIcon icon={["far", "clock"]} /></span>
          {cardDateFormat(auctionClosedTime)}
        </span>
      );
    } else {
      return (
        <span className={`auction-card__time-remaining auction-card__time-remaining--${formatTimeRemainingColor(auctionStatus, timeRemaining)}`}>
          <span className="icon has-margin-right-xs"><FontAwesomeIcon icon={["far", "clock"]} /></span>
          {cardDateFormat(auctionClosedTime)}
        </span>
      );
    }
  }
}

export default AuctionTimeRemaining;
