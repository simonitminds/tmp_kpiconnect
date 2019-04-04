import _ from 'lodash';
import React from 'react';
import moment from 'moment';

export function replaceListItem(list, oldItem, newItem) {
  const index = _.indexOf(list, oldItem);
  if (newItem) {
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

export const convertToMinutes = (milliseconds) => {
  return Math.round(milliseconds / 60000, 0);
}

export const formatUTCDateTime = (dateTime) => {
  if (dateTime) {
    return `${formatDateTime(moment(dateTime).utc())} GMT`;
  } else {
    return "Not Scheduled";
  }
}

export const formatUTCDate = (date) => {
  if (date) {
    return `${formatDate(moment(date).utc())}`;
  } else {
    return "Not Scheduled";
  }
}

export const formatDateTime = (dateTime) => {
  if (dateTime) {
    return moment(dateTime).format("DD/MM/YYYY HH:mm");
  } else {
    return "";
  }
}

export const formatDate = (date) => {
  if (date) {
    return moment(date).format("DD/MM/YYYY");
  } else {
    return "";
  }
}

export const formatMonthYear = (dateTime) => {
  if (dateTime) {
    const newDate = moment(dateTime).format("MMM YYYY");
    return newDate;
  } else {
    return "";
  }
}

export const formatTime = (dateTime) => {
  if (dateTime) {
    return moment(dateTime).utc().format("HH:mm:ss");
  } else {
    return "";
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
  } else if(portId == "") {
    return "No port selected";
  }
}

export function timeRemainingCountdown(auctionPayload, clientTime) {
  const status = _.get(auctionPayload, 'status');
  const timeRemaining = _.get(auctionPayload, 'time_remaining');
  if ((status === "open" || status === "decision") && timeRemaining) {
    const serverTime = moment(auctionPayload.current_server_time);
    const clientServerDiff = clientTime.diff(serverTime);
    const timeLeft = timeRemaining - clientServerDiff;
    return timeLeft;
  } else if (status === "closed") {
    return 0;
  }
}

export function formatTimeRemaining(auctionStatus, timeRemaining, page) {
  let message;
  switch (`${auctionStatus}-${page}`) {
    case "open-show": {message = "remaining in auction"; break;}
    case "open-index": {message = "remaining"; break;}
    case "decision-show": {message = "remaining in decision period"; break;}
    case "decision-index": {message = "remaining"; break;}
  }
  if (timeRemaining && timeRemaining > 0) {
    const mins = Math.floor(timeRemaining / 60000);
    const secs = Math.trunc((timeRemaining - mins * 60000) / 1000);
    return `${leftpad(mins, 2, "0")}:${leftpad(secs, 2, "0")} ${message}`;
  } else if (auctionStatus === "expired") {
    return "Auction Expired"
  } else if (auctionStatus === "closed") {
    return "Auction Closed"
  } else if(auctionStatus === "draft"){
    return "Auction not scheduled";
  } else if(auctionStatus === "pending"){
    return "Auction has not started";
  } else {
    return "00:00 Remaining";
  }
}

export function formatTimeRemainingMobile(auctionStatus, timeRemaining, page) {
  let message;
  switch (`${auctionStatus}-${page}`) {
    case "open-show": {message = "remaining"; break;}
    case "open-index": {message = "remaining"; break;}
    case "decision-show": {message = "remaining"; break;}
    case "decision-index": {message = "remaining"; break;}
  }
  if (timeRemaining && timeRemaining > 0) {
    const mins = Math.floor(timeRemaining / 60000);
    const secs = Math.trunc((timeRemaining - mins * 60000) / 1000);
    return `${leftpad(mins, 2, "0")}:${leftpad(secs, 2, "0")} ${message}`;
  } else if (auctionStatus === "expired") {
    return "Auction Expired"
  } else if (auctionStatus === "closed") {
    return "Auction Closed"
  } else if(auctionStatus === "draft"){
    return "Unscheduled";
  } else if(auctionStatus === "pending"){
    return "Not started";
  } else {
    return "00:00 Remaining";
  }
}

export function formatTimeRemainingColor(auctionStatus, timeRemaining) {
  if (timeRemaining && auctionStatus === "open") {
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
  else if (timeRemaining && auctionStatus === "decision") {
    return `in-decision`;
  }
  else {
    return `inactive`;
  }
}

export function cardDateFormat(time, fallback) {
  return time ? moment(time).format("DD MMM YYYY, k:mm") : (fallback || "Not Scheduled");
}

export function etaAndEtdForAuction(auction) {
  const vesselFuels = _.get(auction, 'auction_vessel_fuels');
  const eta = _.chain(vesselFuels).map('eta').min().value() || auction.eta;
  const etd = _.chain(vesselFuels).map('etd').min().value() || auction.etd;
  return { eta, etd };
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

export function formatPrice(rawPrice) {
  return (+(rawPrice)).toFixed(2)
}

export function quickOrdinal(order) {
  return["st","nd","rd"][((order+90)%100-10)%10-1]||"th"
}
