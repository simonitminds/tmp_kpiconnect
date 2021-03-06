import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { formatTime, formatPrice } from '../../utilities';
import SolutionAcceptDisplay from './solution-accept-display';
import SolutionDisplayBarges from './solution-display-barges';
import SolutionDisplayProductPrices from './solution-display-product-prices';
import SolutionDisplayProductSection from './solution-display-product-section';
import MediaQuery from 'react-responsive';
import BidTag from './bid-tag';

export default class SolutionDisplay extends React.Component {
  constructor(props) {
    super(props);
    const isExpanded = this.props.isExpanded;

    this.container = React.createRef();
    this.state = {
      selected: false,
      expanded: isExpanded,
      hasOverflow: false,
      overflowTimer: null,
    }
  }
  componentWillUnmount() {
    clearTimeout(this.state.overflowTimer);
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
    const bidIds = _.map(this.props.solution.bids, 'id');
    const auctionId = this.props.auctionPayload.auction.id;
    this.props.acceptSolution(auctionId, bidIds, e);
    return false;
  }

  toggleExpanded(e) {
    e.preventDefault();
    this.setState({expanded: !this.state.expanded});
  }

  toggleOverflow(e) {
      this.setState({hasOverflow: true});
      let timer = setTimeout(() => {this.setState({hasOverflow: false})}, 750);
      this.setState({overflowTimer: timer})
    return false;
  }

  render() {
    const {auctionPayload, solution, title, acceptSolution, supplierId, revokeBid, highlightOwn, best, children, className, isBuyer} = this.props;
    const userIsBuyer = isBuyer || false;
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
    const revokable = isSupplier && revokeBid && !isBuyer && _.includes(['pending', 'open'], auctionStatus);
    const isExpanded = this.state.expanded;

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
      <div className={`box auction-solution ${className || ''} auction-solution--${isExpanded ? "open":"closed"}${this.state.hasOverflow ? " overflow--hidden" : ""}`} ref={this.container} onClick={this.toggleOverflow.bind(this)}>
        <div className="auction-solution__header auction-solution__header--bordered">
          <div className="auction-solution__header__row">
            <h3 className="auction-solution__title qa-auction-solution-expand" onClick={this.toggleExpanded.bind(this)}>
              { isExpanded
                ? <FontAwesomeIcon icon="minus" className="has-padding-right-md" />
                : <FontAwesomeIcon icon="plus" className="has-padding-right-md" />
              }
              <span className="is-inline-block">
                <span className="auction-solution__title__category">{title}</span>
                <span className="auction-solution__title__description">{solutionTitle()}</span>
              </span>
              <MediaQuery query="(max-width: 480px)">
                { acceptable &&
                  <button className="button is-small has-margin-left-md qa-auction-select-solution" onClick={this.selectSolution.bind(this)}>Select</button>
                }
              </MediaQuery>
            </h3>
            <div className="auction-solution__content">
              <span className="has-text-weight-bold has-padding-right-xs">${formatPrice(normalized_price)}</span>
              ({formatTime(latest_time_entered)})
              <MediaQuery query="(min-width: 480px)">
                { acceptable &&
                  <button className="button is-small has-margin-left-md qa-auction-select-solution" onClick={this.selectSolution.bind(this)}>Select</button>
                }
              </MediaQuery>
            </div>
          </div>
          <SolutionDisplayProductPrices lowestFuelBids={lowestFuelBids} supplierId={supplierId} highlightOwn={highlightOwn} />
        </div>

        <div className="auction-solution__body">
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
        </div>
        { acceptable && this.state.selected &&
          <SolutionAcceptDisplay auctionPayload={auctionPayload} bestSolutionSelected={best} acceptSolution={this.onConfirm.bind(this)} cancelSelection={this.cancelSelection.bind(this)} />
        }
      </div>
    );
  }
};
