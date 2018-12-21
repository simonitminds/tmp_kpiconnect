import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import moment from 'moment';
import {
  convertToMinutes,
  formatUTCDateTime,
  formatTimeRemaining,
  formatTimeRemainingMobile,
  formatTimeRemainingColor,
  timeRemainingCountdown
} from '../../utilities';
import ServerDate from '../../serverdate';
import ChannelConnectionStatus from './channel-connection-status';

class AuctionHeaderTimers extends React.Component {
  constructor(props) {
    super(props);
    const serverTime = moment(ServerDate.now()).utc();
    this.state = {
      serverTime: serverTime,
      timeRemaining: timeRemainingCountdown(props.auctionPayload, serverTime)
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
    let time = moment(ServerDate.now()).utc();
    this.setState({
      serverTime: time,
      timeRemaining: timeRemainingCountdown(this.props.auctionPayload, time)
    });
  }

  render() {
    const { auctionPayload, isMobile, connection } = this.props;
    const { status } = auctionPayload;
    const { serverTime, timeRemaining } = this.state;

    if(isMobile) {
      return (
        <React.Fragment>
          <div className="auction-list__timer auction-list__timer--show">
            <FontAwesomeIcon icon={["far", "clock"]} className="has-margin-right-xs" />
            <span className="auction-list__timer__clock" id="gmt-time" >
              {serverTime.format("DD MMM YYYY, k:mm:ss")}
            </span>&nbsp;GMT
          </div>

          <div className={`auction-header__timer auction-header__timer--mobile ${status == "pending" ? "auction-header__timer--mobile--pending" : ""} has-text-left-mobile`}>
            <ChannelConnectionStatus connection={connection} />
            <div className={`auction-timer auction-timer--mobile auction-timer--${formatTimeRemainingColor(status, timeRemaining)}`}>
              <span className="qa-auction-time_remaining" id="time-remaining">
                {formatTimeRemainingMobile(status, timeRemaining, "show")}
              </span>
            </div>
          </div>
        </React.Fragment>
      );
    } else {
      return (
        <React.Fragment>
          <div className="auction-list__timer">
            <FontAwesomeIcon icon={["far", "clock"]} className="has-margin-right-xs" />
            <span className="auction-list__timer__clock" id="gmt-time" >
              {serverTime.format("DD MMM YYYY, k:mm:ss")}
            </span>&nbsp;GMT
          </div>
          <div className="auction-header__timer has-text-left-mobile">
            <ChannelConnectionStatus connection={connection} />
            <div className={`auction-timer auction-timer--${formatTimeRemainingColor(status, timeRemaining)}`}>
              <span className="qa-auction-time_remaining" id="time-remaining">
                {formatTimeRemaining(status, timeRemaining, "show")}
              </span>
            </div>
          </div>
        </React.Fragment>
      );
    }
  }
}

export default AuctionHeaderTimers;
