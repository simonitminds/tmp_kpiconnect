import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { cardDateFormat, timeRemainingCountdown } from '../../utilities';
import ServerDate from '../../serverdate';
import CollapsibleSection from './common/collapsible-section';
import ChannelConnectionStatus from './common/channel-connection-status';
import MediaQuery from 'react-responsive';
import { componentsForAuction } from './common';
import DateRangeInput from '../date-range-input';

export default class HistoricalAuctionsIndex extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      timeRemaining: {},
      serverTime: moment().utc(),
      auctionPayloads: this.props.auctionPayloads,
      filterParams: {
        vessel: "",
        buyer: "",
        supplier: "",
        port: "",
        startTimeRange: null,
        endTimeRange: null,
        claims: ""
      }
    };
  }

  clearFilter(ev) {
    const fields = ev.target.elements;
    _.forEach(fields, field => field.value = "");

    let filterParams = this.state.filterParams;
    filterParams = {...filterParams, startTimeRange: "", endTimeRange: ""}
    this.setState({
      filterParams,
      auctionPayloads: this.props.auctionPayloads
    });

    ev.preventDefault();
  }

  filterByInput(inputName, inputValue) {
    switch (inputName) {
      case "supplier":
        return payload => _
          .chain(payload.solutions)
          .get('winning_solution.bids')
          .some({'supplier': inputValue})
          .value();
      case "vessel":
        return payload => _.some(_.get(payload.auction, inputName + 's'), {'id': parseInt(inputValue)})
      case "buyer":
      case "port":
        return payload => _.isMatch(payload.auction[inputName], {'id': parseInt(inputValue)})
      case "startTimeRange":
        return payload => inputValue.isBefore(moment(payload.auction.scheduled_start), 'day') || inputValue.isSame(moment(payload.auction.scheduled_start), 'day')
      case "endTimeRange":
        return payload => inputValue.isAfter(moment(payload.auction.scheduled_start), 'day') || inputValue.isSame(moment(payload.auction.scheduled_start), 'day')
      case "claims":
        const claimStatus = inputValue === "true";
        return payload => _.some(payload.claims, {closed: claimStatus})
      default:
        return payload => true;
    }
  }

  filteredPayloads(filterParams) {
    const filter = _
      .chain(filterParams)
      .toPairs()
      .filter(([_key, value]) => !!value)
      .map(([key, value]) => this.filterByInput(key, value))
      .overEvery()
      .value();

    return _.filter(this.props.auctionPayloads, filter);
  }

  filterPayloads(ev) {
    let filterParams = this.state.filterParams;
    filterParams = {...filterParams, [ev.target.name]: ev.target.value}

    this.setState({
      auctionPayloads: this.filteredPayloads(filterParams),
      filterParams
    })
  }

  handleTimeRange({ startDate, endDate }) {
    let filterParams = this.state.filterParams;
    filterParams = {...filterParams, startTimeRange: startDate, endTimeRange: endDate}

    this.setState({
      auctionPayloads: this.filteredPayloads(filterParams),
      filterParams
    })
  }

  render() {
    const isWinningSupplier = (auctionPayload, supplierName) => {
      let winningSolution = _
        .chain(auctionPayload)
        .get('solutions.winning_solution')
        .value();
      if (winningSolution) {
        return _.some(winningSolution.bids, {'supplier': supplierName});
      } else {
        return false;
      }
    }

    const availableAuctions = _.map(this.props.auctionPayloads, (payload) => payload.auction);

    const availableAuctionAttributes = (type) => {
      switch (type) {
        case 'vessels':
          return _
            .chain(availableAuctions)
            .flatMap((auction) => auction[type])
            .reject((vessel) => vessel == undefined)
            .uniqBy('id')
            .value();
        case 'suppliers':
          const suppliers = _
            .chain(availableAuctions)
            .flatMap((auction) => auction[type])
            .reject((supplier) => supplier == undefined)
            .uniqBy('id')
            .value();
          const winningSuppliers = _
            .chain(this.props.auctionPayloads)
            .flatMap((payload) => {
              return _.filter(suppliers, (supplier) => isWinningSupplier(payload, supplier.name));
            })
            .uniq()
            .value();

          return winningSuppliers;
        case 'buyer':
        case 'port':
          return _
            .chain(availableAuctions)
            .map((auction)=> auction[type])
            .uniqBy('id')
            .value();
      }
    }
    const availableVessels = availableAuctionAttributes('vessels');
    const availableSuppliers = availableAuctionAttributes('suppliers')
    const availableBuyers = availableAuctionAttributes('buyer');
    const availablePorts = availableAuctionAttributes('port');

    const connection = this.props.connection;
    const currentUserIsAdmin = window.isAdmin && !window.isImpersonating;
    const currentUserIsBuyer = (auction) => { return((parseInt(this.props.currentUserCompanyId) === auction.buyer.id) || currentUserIsAdmin); };

    const filteredAuctionPayloads = (status) => {
      return _.filter(this.state.auctionPayloads, (auctionPayload) => {
          return(auctionPayload.status === status);
        });
    };

    const chronologicalAuctionPayloads = (auctionPayloads, status) => {
      let sortField = 'auction_started';
      switch(status) {
        case 'closed':
          sortField = 'auction_closed_time';
          break;
        case 'cancelled':
        case 'expired':
          sortField = 'auction_closed_time';
          break;
        default:
          sortField = 'id';
          break;
      }
      return _.orderBy(auctionPayloads, [
          auctionPayload => _.get(auctionPayload.auction, sortField),
          auctionPayload => auctionPayload.auction.id
        ],
        ['desc', 'desc']
      );
    };

    const filteredAuctionsDisplay = (status) => {
      const filteredPayloads = chronologicalAuctionPayloads(filteredAuctionPayloads(status), status);
      if(_.isEmpty(filteredPayloads)) {
        return(
          <div className="empty-list">
            <em>You have no {status} auctions</em>
          </div>);
      } else {
        return(
          <div className="columns is-multiline">
            { _.map(filteredPayloads, (auctionPayload) => {
              const auctionType = _.get(auctionPayload, 'auction.type');
              const { BuyerCard, SupplierCard } = componentsForAuction(auctionType);
              if (currentUserIsBuyer(auctionPayload.auction)) {
                return <BuyerCard
                  key={auctionPayload.auction.id}
                  auctionPayload={auctionPayload}
                  timeRemaining={this.state.timeRemaining[auctionPayload.auction.id]}
                />;
              } else {
                return <SupplierCard
                  key={auctionPayload.auction.id}
                  auctionPayload={auctionPayload}
                  timeRemaining={this.state.timeRemaining[auctionPayload.auction.id]}
                  connection={connection}
                  currentUserCompanyId={this.props.currentUserCompanyId}
                />;
              }
            }) }
          </div>);
      }
    };
    const filteredAuctionsCount = (status) => {
      return filteredAuctionPayloads(status).length;
    };

    return (
      <div className="auction-app">
        <div className="auction-app__header auction-app__header--list container is-fullhd">
          <div className="content is-clearfix">
            <MediaQuery query="(max-width: 599px)">
              <div>
                <div className="auction-list__time-box">
                  <ChannelConnectionStatus connection={connection} />
                  <div className="auction-list__timer">
                    <FontAwesomeIcon icon={["far", "clock"]} className="has-margin-right-xs" />
                    <span className="auction-list__timer__clock" id="gmt-time" >
                      {this.state.serverTime.format("DD MMM YYYY, k:mm:ss")}
                    </span>&nbsp;GMT
                  </div>
                </div>
                <a href="/auctions" className="auction-list__new-auction button is-link is-pulled-right is-small has-margin-bottom-md">
                  <span>Current Auctions</span>
                  <span className="icon"><i className="fas fa-arrow-right is-pulled-right"></i></span>
                </a>
              </div>
            </MediaQuery>
            <h1 className="title auction-list__title">Historical Auctions</h1>
            <MediaQuery query="(min-width: 600px)">
              <div>
                <a href="/auctions" className="button is-link is-pulled-right">
                  <span>Current Auctions</span>
                  <span className="icon"><i className="fas fa-arrow-right is-pulled-right"></i></span>
                </a>
                <div className="auction-list__time-box">
                  <ChannelConnectionStatus connection={connection} />
                  <div className="auction-list__timer">
                    <FontAwesomeIcon icon={["far", "clock"]} className="has-margin-right-xs" />
                    <span className="auction-list__timer__clock" id="gmt-time" >
                      {this.state.serverTime.format("DD MMM YYYY, k:mm:ss")}
                    </span>&nbsp;GMT
                  </div>
                    <i className="is-hidden-mobile">Server Time</i>
                </div>
              </div>
            </MediaQuery>
          </div>
        </div>
        <div className="auction-app__body">
          <section className="is-gray-1 has-margin-top-md has-margin-bottom-md">
            <div className="container">
              <div className="content has-padding-top-lg has-padding-bottom-md">
                <h2 className="has-margin-bottom-md"><legend className="subtitle is-4">Filter Auctions</legend></h2>
                <div className="historical-auctions__form">
                  <form onChange={this.filterPayloads.bind(this)} onSubmit={this.clearFilter.bind(this)}>
                    <div className="field">
                      <div className="control">
                        <label className="label">Vessel</label>
                        <div className="select">
                          <select
                            name="vessel"
                            className="qa-filter-vessel_id"
                          >
                            <option value="" >Select Vessel</option>
                            { _.map(availableVessels, vessel => (
                              <option className={`qa-filter-vessel_id-${vessel.id}`} key={vessel.id} value={vessel.id}>
                                {vessel.name}
                              </option>
                            ))}
                          </select>
                        </div>
                      </div>
                    </div>

                    <div className="field">
                      <div className="control">
                        <label className="label">Port</label>
                        <div className="select">
                          <select name="port" className="qa-filter-port_id">
                            <option value="">Select Port</option>
                            {_.map(availablePorts, port => (
                              <option key={port.id} value={port.id} className={`qa-filter-port_id-${port.id}`}>
                                {port.name}
                              </option>
                            ))}
                          </select>
                        </div>
                      </div>
                    </div>

                    <div className="field">
                      <div className="control">
                        <label className="label">Buyer</label>
                        <div className="select">
                          <select name="buyer" className="qa-filter-buyer_id">
                            <option value="">Select Buyer</option>
                            {_.map(availableBuyers, buyer => (
                              <option key={buyer.id} value={buyer.id} className={`qa-filter-buyer_id-${buyer.id}`}>
                                {buyer.name}
                              </option>
                            ))}
                          </select>
                        </div>
                      </div>
                    </div>

                    { availableSuppliers.length > 0 &&
                      <div className="field">
                        <div className="control">
                          <label className="label">Winning Supplier</label>
                          <div className="select">
                            <select name="supplier" className="qa-filter-supplier_id" >
                              <option value="">Select Supplier</option>
                                {_.map(availableSuppliers, supplier => (
                                  <option key={supplier.id} value={supplier.name} className={`qa-filter-supplier_id-${supplier.id}`}>
                                    {supplier.name}
                                  </option>
                                ))}
                            </select>
                          </div>
                        </div>
                      </div>
                    }

                    <div className="field">
                      <div className="control">
                        <label className="label">Claim Status</label>
                        <div className="select">
                          <select name="claims" className="qa-filter-claims">
                            <option value="">Select Status</option>
                            <option value={false} className={`qa-filter-claims-open`}>
                              Open
                            </option>
                            <option value={true} className={`qa-filter-claims-closed`}>
                              Closed
                            </option>
                          </select>
                        </div>
                      </div>
                    </div>

                    <MediaQuery query="(max-width: 599px)">
                      <div className="field">
                        <div className="control">
                          <label className="label">Time Period</label>
                          <DateRangeInput
                            orientation={"vertical"}
                            startDate={this.state.filterParams.startTimeRange}
                            endDate={this.state.filterParams.endTimeRange}
                            onChange={this.handleTimeRange.bind(this)}
                          />
                        </div>
                      </div>
                    </MediaQuery>
                    <MediaQuery query="(min-width: 600px)">
                      <div className="field">
                        <div className="control">
                          <label className="label">Time Period</label>
                          <DateRangeInput
                            startDate={this.state.filterParams.startTimeRange}
                            endDate={this.state.filterParams.endTimeRange}
                            onChange={this.handleTimeRange.bind(this)}
                          />
                        </div>
                      </div>
                    </MediaQuery>
                    <div className="field">
                      <div className="control">
                        <button className="button">Clear Filter</button>
                      </div>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          </section>
          <CollapsibleSection
            trigger="Closed Auctions"
            classParentString="qa-closed-auctions-list auction-list"
            contentChildCount={filteredAuctionsCount("closed")}
            open={filteredAuctionsCount("closed") > 0}
            >
            { filteredAuctionsDisplay("closed") }
          </CollapsibleSection>
          <CollapsibleSection
            trigger="Expired Auctions"
            classParentString="qa-expired-auctions-list auction-list"
            contentChildCount={filteredAuctionsCount("expired")}
            open={filteredAuctionsCount("expired") > 0}
            >
            { filteredAuctionsDisplay("expired") }
          </CollapsibleSection>
          <CollapsibleSection
            trigger="Canceled Auctions"
            classParentString="qa-canceled-auctions-list auction-list"
            contentChildCount={filteredAuctionsCount("canceled")}
            open={filteredAuctionsCount("canceled") > 0}
            >
            { filteredAuctionsDisplay("canceled") }
          </CollapsibleSection>

        </div>
      </div>
    );
  }
}
