import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SolutionAcceptDisplay from './solution-accept-display';
import SolutionDisplayBarges from './solution-display-barges';
import SolutionDisplayVesselSection from './solution-display-vessel-section';
import MediaQuery from 'react-responsive';

export default class SolutionDisplay extends React.Component {
  constructor(props) {
    super(props);
    const isExpanded = this.props.isExpanded;
    this.state = {
      selected: false,
      expanded: isExpanded
    }
  }

  selectSolution() {
    this.setState({selected: true})
  }

  cancelSelection(e) {
    e.preventDefault();
    const selectionWindow = document.querySelector(`.${this.props.className} > .auction-solution__confirmation`);
    selectionWindow.classList.add("clear");
    setTimeout(() => this.setState({selected: false}), 750);
    return(false);
  }

  onConfirm(event) {
    event.preventDefault();
    const bidIds = _.map(this.props.solution.bids, 'id');
    const auctionId = this.props.auctionPayload.auction.id;
    this.props.acceptSolution(auctionId, bidIds, event);
    return(false)
  }

  toggleExpanded(e) {
    e.preventDefault();
    this.setState({expanded: !this.state.expanded});
  }

  render() {
    const {auctionPayload, solution, title, acceptSolution, supplierId, best, children, className} = this.props;
    const isSupplier = !!supplierId;
    const auctionStatus = auctionPayload.status;
    const auctionBarges = _.get(auctionPayload, 'submitted_barges');
    const suppliers = _.get(auctionPayload, 'auction.suppliers');
    const fuels = _.get(auctionPayload, 'auction.fuels');
    const vessels = _.get(auctionPayload, 'auction.vessels');
    const vesselFuels = _.get(auctionPayload, 'auction.auction_vessel_fuels');
    const {bids, normalized_price, total_price, latest_time_entered, valid} = solution;
    const solutionSuppliers = _.chain(bids).map((bid) => bid.supplier).uniq().value();
    const isSingleSupplier = (solutionSuppliers.length == 1);
    const acceptable = !!acceptSolution;
    const isExpanded = this.state.expanded;

    const fuelBids = _.map(bids, (bid) => {
      const fuel = _.find(fuels, (fuel) => fuel.id == bid.fuel_id);
      return {fuel, bid};
    });

    const vesselFuelBids = _.chain(vesselFuels)
      .reduce((acc, vf) => {
        acc[vf] = _.find(bids, (bid) => bid.fuel_id == vf.fuel_id && _.includes(bid.vessel_ids, vf.vessel_id);
          return acc;
      }, {})
      .value();


    const solutionTitle = () => {
      if(isSingleSupplier) {
        return solutionSuppliers[0];
      } else {
        return (
          <span>
            <span className="split-offer-indicator">Split Offer </span>
            <span className="has-text-gray-3">
              ({ _.join(solutionSuppliers, ", ") })
            </span>
          </span>
        );
      }
    };

    return (
      <div className={`box auction-solution ${className || ''} auction-solution--${isExpanded ? "open":"closed"}`}>
        <div className="auction-solution__header auction-solution__header--bordered">
          <h3 className="auction-solution__title qa-auction-solution-expand" onClick={this.toggleExpanded.bind(this)}>
            {isExpanded
              ? <i className="fas fa-minus has-padding-right-md"></i>
              : <i className="fas fa-plus has-padding-right-md"></i>
            }
            <span className="is-inline-block">
              <span className="auction-solution__title__category">{title}</span>
              <span className="auction-solution__title__description">{solutionTitle()}</span>
            </span>
            <MediaQuery query="(max-width: 480px)">
              { acceptable && auctionStatus == 'decision' &&
                <button className="button is-small has-margin-left-md qa-auction-select-solution" onClick={this.selectSolution.bind(this)}>Select</button>
              }
            </MediaQuery>
          </h3>
          <div className="auction-solution__content">
            <span className="has-text-weight-bold has-padding-right-xs">${formatPrice(normalized_price)}</span>
            ({formatTime(latest_time_entered)})
            <MediaQuery query="(min-width: 480px)">
              { acceptable && auctionStatus == 'decision' &&
                <button className="button is-small has-margin-left-md qa-auction-select-solution" onClick={this.selectSolution.bind(this)}>Select</button>
              }
            </MediaQuery>
          </div>
        </div>
        <div className="auction-solution__body">
          { !isSupplier &&
            <div className="auction-solution__barge-section">
              <strong className="is-inline-block has-margin-right-sm">Approved Barges</strong>
              <SolutionDisplayBarges suppliers={suppliers} bids={bids} auctionBarges={auctionBarges} />
            </div>
          }
          { _.map(vesselFuelBids, (vesselFuel, bids) => <SolutionDisplayVesselSection vessel={vessel} bids={bids} supplierId={supplierId} />) }
        </div>
        { acceptable && this.state.selected &&
          <SolutionAcceptDisplay auctionPayload={auctionPayload} bestSolutionSelected={best} acceptSolution={this.onConfirm.bind(this)} cancelSelection={this.cancelSelection.bind(this)} />
        }
      </div>
    );
  }
};
