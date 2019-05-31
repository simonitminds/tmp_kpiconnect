import _ from 'lodash';
import React from 'react';
import { Parser } from 'json2csv';
import fileDownload from 'js-file-download';

export function exportCSV(csv, fileName) {
  fileDownload(csv, fileName);
}

export const parseCSVFromPayloads = (fixturePayloads) => {

  const dataForCSV = _
    .chain(fixturePayloads)
    .map((payload) => {
      const auction = _.get(payload, 'auction');
      const buyer = _.get(auction, 'buyer.name');
      const port = _.get(auction, 'port.name');
      const auctionId = _.get(auction, 'id');
      const closedTime = _.get(auction, 'auction_closed_time');

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
            'closed': closedTime,
            'eta': eta,
            'quantity': quantity
          }

          return jsonForCSVParser;
        })
      )
    })
    .flatten()
    .value();

  console.log(dataForCSV);

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
      label: 'Closed Time',
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
  console.log(csv)
  return csv;
}
