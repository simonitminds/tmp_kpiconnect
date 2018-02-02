import _ from 'lodash';
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

export function formatTimeRemaining(auction) {
  if (auction.time_remaining) {
    const mins = Math.floor(auction.time_remaining / 60);
    const secs = auction.time_remaining - mins * 60;
    return `${mins}:${secs} remaining in auction`
  } else {
    return "Auction has not started"
  }

}
