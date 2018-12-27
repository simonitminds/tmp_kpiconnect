import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { formatTime, formatPrice } from '../../utilities';
import CustomSolutionBidSelector from './custom-solution-bid-selector';
import SolutionAcceptDisplay from './solution-accept-display';
import SolutionDisplayBarges from './solution-display-barges';
import SolutionDisplayProductPrices from './solution-display-product-prices';
import MediaQuery from 'react-responsive';
import BidTag from './bid-tag';

export default class CustomSolutionDisplay extends React.Component {
  constructor(props) {
    super(props);
    const isExpanded = this.props.isExpanded;

    this.container = React.createRef();
    this.state = {
      selected: false,
      isExpanded: isExpanded,
      selectedBids: []
    }
  }

  selectSolution() {
    this.setState({selected: true})
  }

  cancelSelection(e) {
    e.preventDefault();
    const selectionWindow = this.container.current.querySelector(".auction-solution__confirmation");
    selectionWindow.classList.add("clear");
    setTimeout(() => this.setState({selected: false}), 750);
    return false;
  }

  onConfirm(e) {
    e.preventDefault();
    const bidIds = _.map(this.state.selectedBids, 'id');
    const auctionId = this.props.auctionPayload.auction.id;
    this.props.acceptSolution(auctionId, bidIds, e);
    return false;
  }

  toggleExpanded(e) {
    e.preventDefault();
    this.setState({isExpanded: !this.state.isExpanded});
  }

  bidSelected(vesselFuelId, bid) {
    const remainingOldBids = _.reject(this.state.selectedBids, {vessel_fuel_id: `${vesselFuelId}`});
    const newSelectedBids = bid ? [...remainingOldBids, bid] : remainingOldBids;

    this.setState({
      selectedBids: newSelectedBids
    });
  }


  render() {
    const {auctionPayload, acceptSolution, className} = this.props;
    const {isExpanded, selected, selectedBids} = this.state;
    const auctionStatus = auctionPayload.status;
    const auctionBarges = _.get(auctionPayload, 'submitted_barges');
    const suppliers = _.get(auctionPayload, 'auction.suppliers');
    const fuels = _.get(auctionPayload, 'auction.fuels');
    const vessels = _.get(auctionPayload, 'auction.vessels');
    const vesselFuels = _.get(auctionPayload, 'auction.auction_vessel_fuels');
    const acceptable = !!acceptSolution && auctionStatus == 'decision';

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


    return (
      <div className={`box auction-solution ${className || ''} auction-solution--${isExpanded ? "open":"closed"}`} ref={this.container}>
        <div className="auction-solution__header auction-solution__header--bordered">
          <div className="auction-solution__header__row">
            <h3 className="auction-solution__title qa-auction-solution-expand" onClick={this.toggleExpanded.bind(this)}>
              { isExpanded
                ? <FontAwesomeIcon icon="minus" className="has-padding-right-md" />
                : <FontAwesomeIcon icon="plus" className="has-padding-right-md" />
              }
              <span className="is-inline-block">
                <span className="auction-solution__title__category">Custom Split Solution</span>
                <span className="auction-solution__title__description has-text-gray-3">Assemble offer based on all valid product offerings</span>
              </span>
              <MediaQuery query="(max-width: 480px)">
                { acceptable &&
                  <button className="button is-small has-margin-left-md qa-auction-select-solution" onClick={this.selectSolution.bind(this)}>Select</button>
                }
              </MediaQuery>
            </h3>
            <div className="auction-solution__content">
              <MediaQuery query="(min-width: 480px)">
                { acceptable &&
                  <button className="button is-small has-margin-left-md qa-auction-select-solution" onClick={this.selectSolution.bind(this)}>Select</button>
                }
              </MediaQuery>
            </div>
          </div>
          <SolutionDisplayProductPrices lowestFuelBids={lowestFuelBids} highlightOwn={false} />
        </div>

        <div className="auction-solution__body">
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
                  <table className="auction-solution__product-table table is-striped" key={fuel.id}>
                    <thead>
                      <tr>
                        <th colSpan="4">{fuel.name}</th>
                      </tr>
                    </thead>
                    <tbody>
                      { _.map(vesselFuelsForFuel, (vesselFuel) => {
                          const {vessel} = vesselFuel;
                          const bids = _.get(auctionPayload, `product_bids[${vesselFuel.id}].lowest_bids`);

                          return (
                            <tr key={vesselFuel.id} className={`qa-custom-solution-vessel-${vessel.id}`}>
                              <td className="auction-solution__product-table__vessel">{vessel.name} <span className="has-text-gray-3 has-margin-left-xs">({vessel.imo})</span></td>
                              <td className="auction-solution__product-table__bid">
                                <CustomSolutionBidSelector bids={bids} onChange={this.bidSelected.bind(this, vesselFuel.id)} />
                              </td>
                              <td className="auction-solution__product-table__supplier">{bids.length == 1 ? "1 bid" : `${bids.length} bids` } available</td>
                              <td className="auction-solution__product-table__bid-time"></td>
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
        </div>

        { acceptable && selected &&
          <SolutionAcceptDisplay auctionPayload={auctionPayload} bestSolutionSelected={false} acceptSolution={this.onConfirm.bind(this)} cancelSelection={this.cancelSelection.bind(this)} />
        }
      </div>
    );
  }
};
