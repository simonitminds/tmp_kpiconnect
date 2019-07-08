import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { Parser } from 'json2csv';
import { formatUTCDateTime } from './utilities';

export function exportCSV(csv, fileName) {
  if (window.navigator.msSaveOrOpenBlob) {
    const data = [csv];
    const blob = new Blob(data);
    window.navigator.msSaveOrOpenBlob(blob, fileName);
  } else {
    const tempLink = document.createElement('a');
    const data = encodeURI("data:text/csv;charset=utf-8," + csv);
    tempLink.href = data
    tempLink.setAttribute('download', fileName)
    tempLink.click()
  }
}

export const parseCSVFromPayloads = (fixturePayloads) => {
  const dataForCSV = _
    .chain(fixturePayloads)
    .map((payload) => {
      const auction = _.get(payload, 'auction');
      const buyer = _.get(auction, 'buyer.name');
      const port = _.get(auction, 'port.name');
      const auctionId = _.get(auction, 'id');
      const closed = _.get(auction, 'auction_closed_time');

      const fixtures = _.get(payload, 'fixtures');
      return (
        _.map(fixtures, (fixture) => {
          const vessel = _.get(fixture, 'vessel.name');
          const supplier = _.get(fixture, 'supplier.name');
          const fuel = _.get(fixture, 'fuel.name');
          const price = _.get(fixture, 'price');
          const eta = _.get(fixture, 'eta');
          const quantity = _.get(fixture, 'quantity');

          const jsonForCSVParser = {
            'buyer': buyer,
            'port': port,
            'supplier': supplier,
            'auction': auctionId,
            'vessel': vessel,
            'fuel': fuel,
            'price': price,
            'benchmark': null,
            'savings': null,
            'closed': moment(closed).format('DD-MMM-YYYY'),
            'eta': moment(eta).format('DD-MMM-YYYY'),
            'quantity': quantity
          }

          return jsonForCSVParser;
        })
      )
    })
    .flatten()
    .value();

  const fields = [
    {
      label: 'Buyer',
      value: 'buyer'
    },
    {
      label: 'Port',
      value: 'port'
    },
    {
      label: 'Supplier',
      value: 'supplier'
    },
    {
      label: 'Auction ID',
      value: 'auction'
    },
    {
      label: 'Vessel Name',
      value: 'vessel'
    },
    {
      label: 'Fuel Grade',
      value: 'fuel'
    },
    {
      label: 'Price',
      value: 'price'
    },
    {
      label: 'Benchmark',
      value: 'benchmark'
    },
    {
      label: 'Savings',
      value: 'savings'
    },
    {
      label: 'Closed',
      value: 'closed'
    },
    {
      label: 'ETA',
      value: 'eta'
    },
    {
      label: 'Quantity',
      value: 'quantity'
    }
  ];
  const csvParser = new Parser({ fields });
  const csv = csvParser.parse(dataForCSV);
  return csv;
}

export const parseCSVFromEvents = (fixture, auction, events) => {
  const fixtureId = _.get(fixture, 'id');
  const auctionId = _.get(auction, 'id');

  const dataForCSV = _
    .chain(events)
    .map((event) => {
      const timeEntered = _.get(event, 'time_entered');
      const type = _.get(event, 'type');
      const user = _.get(event, 'user');
      let changes = _.get(event, 'changes', {});
      const comment = _.get(changes, 'comment', "");

      changes = _.has(changes, 'comment') ? _
        .chain(changes)
        .omit('comment')
        .value() : changes;

      const previousValues = !!changes ? _
        .chain(changes)
        .toPairs()
        .map(([field, _value]) => {
          console.log(fixture[field])
          switch (field) {
            case "vessel":
              return { [field]: fixture[field].name };
            case "supplier":
              return { [field]: fixture[field].name };
            case "fuel":
              return { [field]: fixture[field].name };
            default:
              return { [field]: fixture[field] };
          }
        })
        .value()
        : [];

      changes = !!changes ? _
        .chain(changes)
        .toPairs()
        .map(([field, value]) => {
          return { [field]: value }
        })
        .value()
        : [];


      console.log(previousValues)

      const userName = !!user ? `${user.first_name} ${user.last_name}` : "";
      const userCompany = !!user ? user.company.name : "";

      const jsonForCSVParser = {
        'timeEntered': moment(timeEntered).format('DD-MMM-YYYY'),
        'type': type,
        'user': userName,
        'userCompany': userCompany,
        'previousValues': previousValues,
        'changes': changes,
        'comment': comment
      }
      return jsonForCSVParser;
    })
    .value();

  const fields = [
    {
      label: 'Time Entered',
      value: 'timeEntered'
    },
    {
      label: 'Type',
      value: 'type'
    },
    {
      label: 'User',
      value: 'user'
    },
    {
      label: 'User Company',
      value: 'userCompany'
    },
    {
      label: 'Previous Fixture Values',
      value: 'previousValues'
    },
    {
      label: 'Fixture Changes',
      value: 'changes'
    },
    {
      label: 'Comment',
      value: 'comment'
    }
  ];

  const csvParser = new Parser({ fields, unwind: ['previousValues', 'changes'] });
  return csvParser.parse(dataForCSV);
}
