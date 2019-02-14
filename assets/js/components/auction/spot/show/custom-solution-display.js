import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import MediaQuery from 'react-responsive';
import { formatTime, formatPrice } from '../../../../utilities';
import CustomSolutionBidSelector from './custom-solution-bid-selector';
import SolutionDisplayWrapper from '../../common/show/solution-display-wrapper';
import SolutionDisplayBarges from '../../common/show/solution-display/solution-display-barges';
import SolutionDisplayProductPrices from './solution-display-product-prices';

export default class CustomSolutionDisplay extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      selectedBids: []
    }
  }

  bidSelected(vesselFuelId, bid) {
    const remainingOldBids = _.reject(this.state.selectedBids, {vessel_fuel_id: `${vesselFuelId}`});
    const newSelectedBids = bid ? [...remainingOldBids, bid] : remainingOldBids;

    this.setState({
      selectedBids: newSelectedBids
    });
  }


  render() {
    const {auctionPayload, className} = this.props;
    const {selectedBids} = this.state;
    const auctionBarges = _.get(auctionPayload, 'submitted_barges');
    const suppliers = _.get(auctionPayload, 'auction.suppliers');
    const fuels = _.get(auctionPayload, 'auction.fuels');
    const vesselFuels = _.get(auctionPayload, 'auction.auction_vessel_fuels');

    const bidsByFuel = _.chain(fuels)
      .reduce((acc, fuel) => {
        const vfIds = _.chain(vesselFuels)
          .filter((vf) => vf.fuel_id == fuel.id)
          .map((vf) => `${vf.id}`)
          .value();
        const fuelBids = _.filter(selectedBids, (bid) => _.includes(vfIds, bid.vessel_fuel_id));
        acc[fuel.name] = fuelBids;
        return acc;
      }, {})
      .value();

    const lowestFuelBids = _.chain(bidsByFuel)
      .reduce((acc, bids, fuel) => {
        acc[fuel] = _.minBy(bids, 'amount');
        return acc;
      }, {})
      .value();

    const totalAmounts = _.reduce(selectedBids, ({quantity, price}, bid) => {
      const vf = _.find(vesselFuels, (vf) => vf.id == bid.vessel_fuel_id);
      return {
        quantity: quantity + vf.quantity,
        price: price + (bid.amount * vf.quantity)
      }
    }, {quantity: 0, price: 0});

    const normalizedPrice = totalAmounts.price / totalAmounts.quantity;
    const displayPrice = selectedBids.length > 0 ? `$${formatPrice(normalizedPrice)}` : "";

    const headerExtras = <SolutionDisplayProductPrices lowestFuelBids={lowestFuelBids} highlightOwn={false} />
    const title = "Custom Split Solution"
    const subtitle = "Assemble offer based on all valid product offerings"

    const solution = {
      bids: selectedBids
    }

    return (
      <SolutionDisplayWrapper title={title} subtitle={subtitle} headerExtras={headerExtras} price={displayPrice} solution={solution} {...this.props} >
        <div className="auction-solution__barge-section">
          <strong className="is-inline-block has-margin-right-sm">Approved Barges</strong>
          <SolutionDisplayBarges suppliers={suppliers} bids={selectedBids} auctionBarges={auctionBarges} />
        </div>

        <div>
          { _.map(fuels, (fuel) => {
              const vesselFuelsForFuel = _.chain(vesselFuels)
                .filter({fuel_id: fuel.id})
                .value();

              return (
                <table className="auction-solution__custom-product-table table is-striped" key={fuel.id}>
                  <thead>
                    <tr>
                      <th>{fuel.name}</th>
                    </tr>
                  </thead>
                  <tbody>
                    { _.map(vesselFuelsForFuel, (vesselFuel) => {
                        const {vessel} = vesselFuel;
                        const bids = _.get(auctionPayload, `product_bids[${vesselFuel.id}].lowest_bids`);

                        return (
                          <tr key={vesselFuel.id} className={`qa-custom-solution-vessel-${vessel.id}`}>
                          <MediaQuery minWidth={940}>
                            <td className="auction-solution__custom-product-table__vessel">{vessel.name} <span className="has-text-gray-3 has-margin-left-xs">({vessel.imo})</span></td>
                            <td className="auction-solution__custom-product-table__bid">
                              <CustomSolutionBidSelector bids={bids} onChange={this.bidSelected.bind(this, vesselFuel.id)} className={`qa-custom-bid-selector-${vesselFuel.id}`} />
                              <span className="select--custom-bid__count">({bids.length == 1 ? "1 bid" : `${bids.length} bids` } available)</span>
                            </td>
                          </MediaQuery>
                            <MediaQuery minWidth={480} maxWidth={768}>
                              <td className="auction-solution__custom-product-table__vessel">{vessel.name} <span className="has-text-gray-3 has-margin-left-xs">({vessel.imo})</span></td>
                              <td className="auction-solution__custom-product-table__bid">
                                <CustomSolutionBidSelector bids={bids} onChange={this.bidSelected.bind(this, vesselFuel.id)} className={`qa-custom-bid-selector-${vesselFuel.id}`} />
                                <span className="select--custom-bid__count">({bids.length == 1 ? "1 bid" : `${bids.length} bids` } available)</span>
                              </td>
                            </MediaQuery>
                            <MediaQuery maxWidth={480}>
                              <td className="auction-solution__custom-product-table__vessel">
                                <div className="auction-solution__custom-product-table__vessel">{vessel.name} <span className="has-text-gray-3 has-margin-left-xs">({vessel.imo})</span></div>
                                <div className="auction-solution__custom-product-table__bid">
                                  <CustomSolutionBidSelector bids={bids} onChange={this.bidSelected.bind(this, vesselFuel.id)} className={`qa-custom-bid-selector-${vesselFuel.id}`} />
                                  <span className="select--custom-bid__count">({bids.length == 1 ? "1 bid" : `${bids.length} bids` } available)</span>
                                </div>
                              </td>
                            </MediaQuery>
                            <MediaQuery minWidth={768} maxWidth={940}>
                              <td className="auction-solution__custom-product-table__vessel">
                                <div className="auction-solution__custom-product-table__vessel">{vessel.name} <span className="has-text-gray-3 has-margin-left-xs">({vessel.imo})</span></div>
                                <div className="auction-solution__custom-product-table__bid">
                                  <CustomSolutionBidSelector bids={bids} onChange={this.bidSelected.bind(this, vesselFuel.id)} className={`qa-custom-bid-selector-${vesselFuel.id}`} />
                                  <span className="select--custom-bid__count">({bids.length == 1 ? "1 bid" : `${bids.length} bids` } available)</span>
                                </div>
                              </td>
                            </MediaQuery>
                          </tr>
                        );
                      })
                    }
                  </tbody>
                </table>
              );
            })
          }
        </div>
      </SolutionDisplayWrapper>
    );
  }
};
