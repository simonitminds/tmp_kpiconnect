import _ from 'lodash';
import React from 'react';
import moment from 'moment';

export function replaceListItem(list, oldItem, newItem) {
  const index = _.indexOf(list, oldItem);
  if(newItem) {
    return [
      ..._.slice(list, 0, index),
      newItem,
      ..._.slice(list, index + 1, list.length)
    ];
  } else {
    return [
      ..._.slice(list, 0, index),
      ..._.slice(list, index + 1, list.length)
    ];
  }
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
    const localTime = moment(gmtTime).utc().add(_.get(port, 'gmt_offset', 0), 'hours');
    return formatDateTime(localTime);
  }
}

export function timeRemainingCountdown(auction, timeRemaining, interval) {
  const status = _.get(auction, 'state.status');
  if ((status === "open" || status === "decision") && _.get(auction, 'state.time_remaining')) {
    if(timeRemaining){

      return timeRemaining - interval;
    } else {
      return auction.state.time_remaining;
    }
  } else if (_.get(auction, 'state.status') === "closed") {
    return 0;
  }
}

export function formatTimeRemaining(auction, timeRemaining, page) {
  const status = _.get(auction, 'state.status');
  let message;
  switch (`${status}-${page}`) {
    case "open-show": {message = "remaining in auction"; break;}
    case "open-index": {message = "remaining"; break;}
    case "decision-show": {message = "remaining in decision period"; break;}
    case "decision-index": {message = "remaining"; break;}
  }
  if (timeRemaining && timeRemaining != 0) {
    const mins = Math.floor(timeRemaining / 60000);
    const secs = Math.trunc((timeRemaining - mins * 60000) / 1000);
    return `${leftpad(mins, 2, "0")}:${leftpad(secs, 2, "0")} ${message}`;
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
    if (timeRemaining <= 60100) { // 1 minute plus time for transition animation.
      return `under-1`;
    }
    else if (timeRemaining <= 180100) { // 3 minutes plus time for transition animation.
      return `under-3`;
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
