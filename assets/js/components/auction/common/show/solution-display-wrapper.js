import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { formatTime, formatPrice } from '../../../../utilities';
import MediaQuery from 'react-responsive';
import BidTag from '../bid-tag';
import SolutionAcceptDisplay from './solution-display/solution-accept-display';


export default class SolutionDisplayWrapper extends React.Component {
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
    const {auctionPayload, solution, title, subtitle, acceptSolution, supplierId, revokeBid, highlightOwn, best, children, headerExtras, className, price} = this.props;
    const {bids, normalized_price, total_price, latest_time_entered, valid} = solution;
    const solutionSuppliers = _.chain(bids).map((bid) => bid.supplier).uniq().value();
    const isSingleSupplier = (solutionSuppliers.length == 1);
    const acceptable = !!acceptSolution;
    const isExpanded = this.state.expanded;

    const displayPrice = price != undefined ? price : `$${formatPrice(normalized_price)}`;

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

    const displaySubtitle = subtitle || solutionTitle();

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
                <span className="auction-solution__title__description">{displaySubtitle}</span>
              </span>
              <MediaQuery query="(max-width: 480px)">
                { acceptable &&
                  <button className="button is-small has-margin-left-md qa-auction-select-solution" onClick={this.selectSolution.bind(this)}>Select</button>
                }
              </MediaQuery>
            </h3>
            <div className="auction-solution__content">
              <span className="has-text-weight-bold has-padding-right-xs">{displayPrice}</span>
              {latest_time_entered &&
                `(${formatTime(latest_time_entered)})`
              }
              <MediaQuery query="(min-width: 480px)">
                { acceptable &&
                  <button className="button is-small has-margin-left-md qa-auction-select-solution" onClick={this.selectSolution.bind(this)}>Select</button>
                }
              </MediaQuery>
            </div>
          </div>
          {headerExtras}
        </div>

        <div className="auction-solution__body">
          {children}
        </div>
        { acceptable && this.state.selected &&
          <SolutionAcceptDisplay auctionPayload={auctionPayload} bestSolutionSelected={best} acceptSolution={this.onConfirm.bind(this)} cancelSelection={this.cancelSelection.bind(this)} />
        }
      </div>
    );
  }
};
