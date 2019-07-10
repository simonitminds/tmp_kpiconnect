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

function formatDateForReport(date) {
  return !!date ? moment(date).format('DD-MM-YYYY') : '';
}

function formatDateTimeForReport(date) {
  return !!date ? moment(date).format('DD-MM-YYYY HH:mm:ss') : '';
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
      const changes = _.get(event, 'changes', {});
      const comment = _.get(changes, 'comment', "");

      const userName = !!user ? `${user.first_name} ${user.last_name}` : "";
      const userCompany = !!user ? user.company.name : "";

      const jsonForCSVParser = {
        'timeEntered': formatDateTimeForReport(timeEntered),
        'type': type,
        'user': userName,
        'userCompany': userCompany,
        'supplier': attributeForEvent('supplier', event, fixture),
        'vessel': attributeForEvent('vessel', event, fixture),
        'fuel': attributeForEvent('fuel', event, fixture),
        'price': attributeForEvent('price', event, fixture),
        'quantity': attributeForEvent('quantity', event, fixture),
        'eta': formatDateTimeForReport(attributeForEvent('eta', event, fixture)),
        'etd': formatDateTimeForReport(attributeForEvent('ets', event, fixture)),
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
      label: 'Supplier',
      value: 'supplier'
    },
    {
      label: 'Vessel',
      value: 'vessel'
    },
    {
      label: 'Fuel',
      value: 'fuel'
    },
    {
      label: 'Price',
      value: 'price'
    },
    {
      label: 'Quantity',
      value: 'quantity'
    },
    {
      label: 'ETA',
      value: 'eta'
    },
    {
      label: 'ETD',
      value: 'etd'
    },
    {
      label: 'Comment',
      value: 'comment'
    }
  ];

  const csvParser = new Parser({ fields });
  return csvParser.parse(dataForCSV);
}

function attributeForEvent(key, event, fixture) {
  const type = _.get(event, 'type');
  let changes = _.get(event, 'changes', {});
  changes = _.has(changes, 'comment') ? _
    .chain(changes)
    .omit('comment')
    .value() : changes;

  switch(type) {
    case 'Fixture changes proposed':
    case 'Fixture updated':
      return _.get(changes, key, '');
    case 'Fixture delivered':
      switch(key) {
        case 'fuel':
        case 'vessel':
        case 'supplier':
          return _.get(fixture, `delivered_${key}.name`, '');
        case 'default':
          return _.get(fixture, key, '');
      }
    default: // Fixture created
      switch(key) {
        case 'fuel':
        case 'vessel':
        case 'supplier':
          return _.get(fixture, `original_${key}.name`, '');
        case 'default':
          return _.get(fixture, key, '');
      }
  }
}
