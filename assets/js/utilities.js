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

export const formatGMTDateTime = (dateTime) => {
  return formatDateTime(moment(dateTime).utc());
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
  const status = _.get(auction, 'state.status');
  if ((status === "open" || status === "decision") && _.get(auction, 'state.time_remaining')) {
    const serverTime = moment(auction.state.current_server_time);
    const timeLeft = auction.state.time_remaining - clientTime.diff(serverTime);
    return timeLeft;
  } else if (_.get(auction, 'state.status') === "closed") {
    return 0;
  }
}

export function formatTimeRemaining(auction, timeRemaining) {
  const status = _.get(auction, 'state.status');

  if (timeRemaining && status === "open") {
    const mins = Math.floor(timeRemaining / 60000);
    const secs = Math.trunc((timeRemaining - mins * 60000) / 1000);
    return `${leftpad(mins, 2, "0")}:${leftpad(secs, 2, "0")} remaining in auction`;
  }
  else if (timeRemaining && status == "decision") {
    const mins = Math.floor(timeRemaining / 60000);
    const secs = Math.trunc((timeRemaining - mins * 60000) / 1000);
    return `${leftpad(mins, 2, "0")}:${leftpad(secs, 2, "0")} remaining in decision period`;
  } else {
    if (timeRemaining === 0) {
      return "Auction Closed"
    } else {
      return "Auction has not started";
    }
  }
}

export function formatTimeRemainingColor(auction, timeRemaining) {
  const status = _.get(auction, 'state.status');

  if (timeRemaining && status === "open") {
    if (Math.floor(timeRemaining / 60000) < 3) {
      return `under-3`;
    }
    else if (Math.floor(timeRemaining / 60000) < 7) {
      return `under-7`;
    }
    else {
      return `active`;
    }
  }
  else if (timeRemaining && status === "decision") {
    return `in-decision`;
  }
  else {
    return `inactive`;
  }
}

export function leftpad (str, len, ch) {
  if (!ch) ch = ' ';
  let new_str = String(str);

  len = len - new_str.length;
  let i = -1;
  while (++i < len) {
    new_str = ch + new_str;
  }

  return new_str;
}
