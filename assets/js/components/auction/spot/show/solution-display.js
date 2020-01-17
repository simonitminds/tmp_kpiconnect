import React from 'react';
import _ from 'lodash';
import SolutionDisplayWrapper from '../../common/show/solution-display-wrapper';
import SolutionDisplayBarges from '../../common/show/solution-display/solution-display-barges';
import SolutionDisplayProductSection from './solution-display/product-section';
import SolutionDisplayProductPrices from './solution-display/product-prices';

const SolutionDisplay = (props) => {
  const {auctionPayload, solution, title, acceptSolution, supplierId, revokeBid, highlightOwn, best, className} = props;
  const isObserver = window.isObserver;
  const isSupplier = !!supplierId && !isObserver;
  const auctionStatus = auctionPayload.status;
  const auctionBarges = _.get(auctionPayload, 'submitted_barges');
  const suppliers = _.get(auctionPayload, 'auction.suppliers');
  const fuels = _.get(auctionPayload, 'auction.fuels');
  const vessels = _.get(auctionPayload, 'auction.vessels');
  const vesselFuels = _.get(auctionPayload, 'auction.auction_vessel_fuels');
  const {bids} = solution;
  const solutionSuppliers = _.chain(bids).map((bid) => bid.supplier).uniq().value();
  const isSingleSupplier = (solutionSuppliers.length == 1);
  const revokable = isSupplier && !!revokeBid && _.includes(['pending', 'open'], auctionStatus);

  const bidsByFuel = _.chain(fuels)
    .reduce((acc, fuel) => {
      const vfIds = _.chain(vesselFuels)
        .filter((vf) => vf.fuel_id == fuel.id)
        .map((vf) => `${vf.id}`)
        .value();
      const fuelBids = _.filter(bids, (bid) => _.includes(vfIds, bid.vessel_fuel_id));
      acc[fuel.name] = fuelBids;
      return acc;
    }, {})
    .value();

  const lowestFuelBids = _.chain(bidsByFuel)
    .reduce((acc, bids, fuel) => {
      acc[fuel] = _.minBy(bids,'amount');
      return acc;
    }, {})
    .value();

  const headerExtras = <SolutionDisplayProductPrices lowestFuelBids={lowestFuelBids} supplierId={supplierId} highlightOwn={highlightOwn} />

  return (
    <SolutionDisplayWrapper headerExtras={headerExtras} {...props} >
      { !isSupplier &&
        <div className="auction-solution__barge-section">
          <strong className="is-inline-block has-margin-right-sm">Approved Barges</strong>
          <SolutionDisplayBarges suppliers={suppliers} bids={bids} auctionBarges={auctionBarges} />
        </div>
      }
      { _.map(bidsByFuel, (bids, fuelName) => {
          const fuel = _.find(fuels, {name: fuelName});
          return (
            <SolutionDisplayProductSection
              key={fuelName}
              fuel={fuel}
              bids={bids}
              vesselFuels={vesselFuels}
              supplierId={supplierId}
              revokable={revokable}
              revokeBid={revokeBid}
              highlightOwn={highlightOwn}
              auctionPayload={auctionPayload}
            />
          );
        })
      }
    </SolutionDisplayWrapper>
  );
}

export default SolutionDisplay;
