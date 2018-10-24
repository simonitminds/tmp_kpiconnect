import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SolutionAcceptDisplay from './solution-accept-display';

export default class SolutionDisplay extends React.Component {
  constructor(props) {
    super(props);
    const isExpanded = this.props.isExpanded;
    this.state = {
      selected: false,
      expanded: isExpanded
    }
  }
  cancelSelection(e) {
    e.preventDefault();
    this.setState({selected: false})
    return(false);
  }
  selectSolution() {
    this.setState({selected: true})
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
    const auctionId = auctionPayload.auction.id;
    const auctionStatus = auctionPayload.status;
    const suppliers = _.get(auctionPayload, 'auction.suppliers');
    const fuels = _.get(auctionPayload, 'auction.fuels');
    const {bids, normalized_price, total_price, latest_time_entered} = solution;
    const bidIds = _.map(bids, 'id');
    const fuelBids = _.map(bids, (bid) => {
      const fuel = _.find(fuels, (fuel) => fuel.id == bid.fuel_id);
      return {fuel, bid};
    });
    const solutionSuppliers = _.chain(bids)
      .map((bid) => bid.supplier)
      .uniq()
      .value();
    const isSingleSupplier = (solutionSuppliers.length == 1);


    const vesselFuels = _.get(auctionPayload, 'auction.auction_vessel_fuels');
    const fuelQuantities = _.chain(fuels)
        .reduce((acc, fuel) => {
          acc[fuel.id] = _.chain(vesselFuels).filter((vf) => vf.fuel_id == fuel.id).sumBy((vf) => vf.quantity).value();
          return acc;
        }, {})
        .value();
    const totalQuantity = _.sum(Object.values(fuelQuantities));
    const acceptable = !!acceptSolution;
    const isExpanded = this.state.expanded;

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
    const isTradedBid = (bid) => {
      return(
        <span>
          { bid.is_traded_bid ?
            <i action-label="Traded Bid" className="fas fa-exchange-alt has-margin-left-sm has-text-gray-3 auction__traded-bid-marker"></i>
          : "" }
        </span>
      );
    }

    const supplierName = (bid) => {
      if(supplierId) {
        return bid.supplier_id == supplierId ? "Your Bid" : "";
      } else {
        return bid.supplier;
      }
    }

    const renderBid = (bid, fuel) => {
      return (
        <tr key={fuel.id} className={`qa-auction-bid-${bid.id}`}>
          <td>{fuel.name}</td>

          <td>
            { bid
              ? <span>
                  <span className="qa-auction-bid-amount">${formatPrice(bid.amount)}<span className="has-text-gray-3">/unit</span> &times; {fuelQuantities[fuel.id]} MT </span>
                  <span className="qa-auction-bid-is_traded_bid">{isTradedBid(bid)}</span>
                </span>
              : <i>No bid</i>
            }
          </td>
          <td><span className="qa-auction-bid-supplier">{ supplierName(bid) }</span></td>
          <td><span className="qa-auction-bid-supplier">{ formatTime(bid.time_entered) }</span></td>
        </tr>
      );
    }

    return (
      <div className={`box auction-solution ${className || ''} auction-solution--${isExpanded ? "open":"closed"}`}>
        <div className="auction-solution__header auction-solution__header--bordered">
          <h3 className="auction-solution__title" onClick={this.toggleExpanded.bind(this)}>
            {isExpanded ?
              <i className="fas fa-minus has-padding-right-md"></i>:
              <i className="fas fa-plus has-padding-right-md"></i>
            }
            <span className="is-inline-block">
              <span className="auction-solution__title__category">{title}</span>
              <span className="auction-solution__title__description">{solutionTitle()}</span>
            </span>
          </h3>
          <div className="auction-solution__content">
            <span className="has-text-weight-bold has-padding-right-xs">${formatPrice(normalized_price)}</span>
            ({formatTime(latest_time_entered)})
            { acceptable && auctionStatus == 'decision' &&
              <button className="button is-small has-margin-left-md qa-auction-select-solution" onClick={this.selectSolution.bind(this)}>Select</button>
            }
          </div>
        </div>
        <div className="auction-solution__body">
          <div>
            <table className="auction-solution__product-table table is-striped">
              <thead>
                <tr>
                  <th colSpan="3">Fuels</th>
                </tr>
              </thead>
              <tbody>
                { bids.length > 0  ?
                    fuelBids.map(({fuel, bid}) => renderBid(bid, fuel))
                    : <tr>
                        <td>
                          <i>No bids have been placed on this auction</i>
                        </td>
                      </tr>
                }
              </tbody>
            </table>
          </div>
        </div>
        { acceptable && this.state.selected &&
          <SolutionAcceptDisplay auctionPayload={auctionPayload} bestSolutionSelected={best} acceptSolution={this.onConfirm.bind(this)} cancelSelection={this.cancelSelection.bind(this)} />
        }
      </div>
    );
  }
};
