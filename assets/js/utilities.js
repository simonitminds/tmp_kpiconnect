import _ from 'lodash';
import React from 'react';
import moment from 'moment';

export function replaceListItem(list, oldItem, newItem) {
  const index = _.indexOf(list, oldItem);
  return [
    ..._.slice(list, 0, index),
    newItem,
    ..._.slice(list, index + 1, list.length)
  ];
}

export const formatDateTime = (dateTime) => {
  if (dateTime) {
    return moment(dateTime).format("DD/MM/YYYY HH:mm");
  } else {
    return ""
  }
}

export const portLocalTime = (gmtTime, portId, ports) => {
  if (gmtTime && portId != "" && ports != null) {
    const port = _.chain(ports)
      .filter(['id', parseInt(portId)])
      .first()
      .value();
    const localTime = moment(gmtTime).add(port.gmt_offset, 'hours');
    return formatDateTime(localTime);
  }
}

export function timeRemainingCountdown(auction, clientTime) {
  if (_.get(auction, 'state.status') == "open" && _.get(auction, 'state.time_remaining')) {
    const serverTime = moment(auction.state.current_server_time);
    const timeLeft = auction.state.time_remaining - clientTime.diff(serverTime);
    return formatTimeRemaining(auction, timeLeft);
  }
}

export function formatTimeRemaining(auction, timeLeft = null) {
  if (_.get(auction, 'state.status') == "open" && _.get(auction, 'state.time_remaining')) {
    let timeRemaining;
    if (timeLeft) {
      timeRemaining = timeLeft;
    } else {
      timeRemaining = auction.state.time_remaining;
    }
    const mins = Math.floor(timeRemaining / 60000);
    const secs = Math.trunc((timeRemaining - mins * 60000) / 1000);
    return `${mins}:${secs} remaining in auction`;
  } else {
    return "Auction has not started";
  }

}
