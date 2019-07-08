import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import MediaQuery from 'react-responsive';
import DateRangeInput from '../date-range-input';
import CheckBoxField from '../check-box-field';
import CollapsibleSection from './common/collapsible-section';
import AuctionTitle from './common/auction-title';
import FixtureReportContainer from '../../containers/fixture-report-container';
import { formatUTCDateTime, formatPrice } from '../../utilities';
import { exportCSV, parseCSVFromPayloads } from '../../reporting-utilities';

export default class AuctionFixturesIndex extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      serverTime: moment().utc(),
      fixturePayloads: _.filter(this.props.fixturePayloads, (payload) => payload.fixtures.length > 0),
      filterParams: {
        vessel: "",
        buyer: "",
        supplier: "",
        port: "",
        startTimeRange: null,
        endTimeRange: null,
      },
      reportsCSV: parseCSVFromPayloads(_.filter(this.props.fixturePayloads, (payload) => payload.fixtures.length > 0)),
      displayFixtureReport: false,
      selectedFixtureForReport: null,
    }
  }

  clearFilter(ev) {
    const fields = ev.target.elements;
    _.forEach(fields, field => field.value = "");

    let filterParams = this.state.filterParams;
    filterParams = {...filterParams, startTimeRange: null, endTimeRange: null}

    this.setState({
      filterParams,
      fixturePayloads: _.filter(this.props.fixturePayloads, (payload) => payload.fixtures.length > 0)
    });

    ev.preventDefault();
  }

  filterByInput(inputName, inputValue) {
    switch (inputName) {
      case "supplier":
        return payload => _
          .chain(payload.fixtures)
          .map((fixture) => fixture[inputName])
          .some({id: parseInt(inputValue)})
          .value();
      case "vessel":
        return payload => _.some(_.get(payload.auction, inputName + 's'), {id: parseInt(inputValue)})
      case "buyer":
      case "port":
        return payload => _.isMatch(payload.auction[inputName], {'id': parseInt(inputValue)})
      case "startTimeRange":
        return payload => inputValue.isBefore(moment(payload.auction.scheduled_start), 'day') || inputValue.isSame(moment(payload.auction.scheduled_start), 'day')
      case "endTimeRange":
        return payload => inputValue.isAfter(moment(payload.auction.scheduled_start), 'day') || inputValue.isSame(moment(payload.auction.scheduled_start), 'day')
      default:
        return payload => true;
    }
  }

  filterBySupplier(inputName, inputValue) {
    switch(inputName) {
      case "supplier":
        return fixture => _.isMatch(fixture, {supplier_id: parseInt(inputValue)});
      default:
        return payload => true;
    }
  }

  filteredPayloads(filterParams) {
    const filter = _.chain(filterParams)
      .toPairs()
      .filter(([key, value]) => !!value)
      .map(([key, value]) => this.filterByInput(key, value))
      .overEvery()
      .value();
    const supplierFilter = _
      .chain(filterParams)
      .toPairs()
      .filter(([key, value]) => !!value && key === "supplier")
      .map(([key, value]) => this.filterBySupplier(key, value))
      .overEvery()
      .value();
    let payloads = _.filter(this.props.fixturePayloads, (payload) => payload.fixtures.length > 0)
    const filteredFixturesForPayload = (payload, filter) => {
      return _
        .chain(payload.fixtures)
        .filter(filter)
        .value();
    }
    payloads = _
      .chain(payloads)
      .map((payload) => {
        return {auction: payload.auction, fixtures: filteredFixturesForPayload(payload, supplierFilter)}
      })
      .value();
    return _.filter(payloads, filter);
  }

  filterPayloads(ev) {
    let filterParams = this.state.filterParams;
    filterParams = {...filterParams, [ev.target.name]: ev.target.value}

    const fixturePayloads = this.filteredPayloads(filterParams);
    const reportsCSV = parseCSVFromPayloads(fixturePayloads);
    this.setState({
      fixturePayloads,
      filterParams,
      reportsCSV
    })
  }

  handleTimeRange({ startDate, endDate }) {
    let filterParams = this.state.filterParams;
    filterParams = {...filterParams, startTimeRange: startDate, endTimeRange: endDate}

    const fixturePayloads = this.filteredPayloads(filterParams);
    const reportsCSV = parseCSVFromPayloads(fixturePayloads);
    this.setState({
      fixturePayloads,
      filterParams,
      reportsCSV
    })
  }

  handleExportClick(_ev) {
    const csv = this.state.reportsCSV;
    const fileName = () => {
      let startDate = this.state.startTimeRange;
      let endDate = this.state.endTimeRange;
      startDate = moment(startDate).format('DD-MM-YYYY');
      endDate = moment(endDate).format('DD-MM-YYYY');
      if ((startDate && endDate) && (!moment().isSame(moment(), startDate) && !moment().isSame(moment(), endDate))) {
        return `benchmark_reports_${startDate}` + '_' + `${endDate}.csv`;
      } else {
        return 'benchmark_reports.csv';
      }
    }
    exportCSV(csv, fileName());
  }

  handleReportClick(fixture, ev) {
    const selectedReportCheckbox = this.state.selectedReportCheckbox;
    const previouslySelectedFixture = this.state.selectedFixtureForReport;

    if (previouslySelectedFixture && !previouslySelectedFixture.delivered && !_.isEqual(selectedReportCheckbox, ev)) {
      selectedReportCheckbox.checked = false;
    }

    this.setState({
      selectedFixtureForReport: fixture,
      displayFixtureReport: ev.target.checked,
      selectedReportCheckbox: ev.target
    })
  }

  handleReportClick(fixture, ev) {
    ev.preventDefault();
    if (this.state.displayFixtureReport) {
      this.setState({
        selectedFixtureForReport: null,
        displayFixtureReport: false,
      })
    } else {
      this.setState({
        selectedFixtureForReport: fixture,
        displayFixtureReport: true,
      })
    }
  }

  render() {
    const availableAuctions = _
      .chain(this.props.fixturePayloads)
      .filter((payload) => payload.fixtures.length > 0)
      .map((payload) => payload.auction);

    const availableFixtureAttributes = (type) => {
      switch (type) {
        case 'vessels':
        case 'suppliers':
          return _
            .chain(availableAuctions)
            .flatMap((auction) => auction[type])
            .reject((supplier) => supplier == undefined)
            .uniqBy('id')
            .value();
        case 'buyer':
        case 'port':
          return _
            .chain(availableAuctions)
            .map((auction) => auction[type])
            .uniqBy('id')
            .value();
      }
    }

    const availableVessels = availableFixtureAttributes('vessels');
    const availableSuppliers = availableFixtureAttributes('suppliers');
    const availableBuyers = availableFixtureAttributes('buyer');
    const availablePorts = availableFixtureAttributes('port');

    const renderFilterForm = () => {
      return (
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
                        <label className="label">Supplier</label>
                        <div className="select">
                          <select name="supplier" className="qa-filter-supplier_id" >
                            <option value="">Select Supplier</option>
                              {_.map(availableSuppliers, supplier => (
                                <option key={supplier.id} value={supplier.id} className={`qa-filter-supplier_id-${supplier.id}`}>
                                  {supplier.name}
                                </option>
                              ))}
                          </select>
                        </div>
                      </div>
                    </div>
                  }

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
      );
    }
    const connection = this.props.connection;
    const currentUserIsAdmin = window.isAdmin && !window.isImpersonating;
    const currentUserIsBuyer = (auction) => { return((parseInt(this.props.currentUserCompanyId) === auction.buyer.id) || currentUserIsAdmin); };


    const fixturePayloads = this.state.fixturePayloads;

    return(
      <div className="auction-app">
        <div className="auction-app__header auction-app__header--list container is-fullhd">
          <div className="content is-clearfix">
            <MediaQuery query="(max-width: 599px)">
              <div>
                <div className="auction-list__time-box">
                  <div className="auction-list__timer">
                    <FontAwesomeIcon icon={["far", "clock"]} className="has-margin-right-xs" />
                    <span className="auction-list__timer__clock" id="gmt-time" >
                      {this.state.serverTime.format("DD MMM YYYY, k:mm:ss")}
                    </span>&nbsp;GMT
                  </div>
                </div>
                <button className="auction_list__new-auction button is-link is-pulled-right is-small has-margin-bottom-md" onClick={this.handleExportClick.bind(this)}>
                  <span>Export Benchmarking Reports</span>
                  <span className="icon"><i className="fas fa-file-export is-pulled-right"></i></span>
                </button>
              </div>
            </MediaQuery>
            <h1 className="title auction-list__title">Auction Fixtures</h1>
            <MediaQuery query="(min-width: 600px)">
              <div>
                <button className="button is-link is-pulled-right" onClick={this.handleExportClick.bind(this)}>
                  <span>Export Benchmarking Reports</span>
                  <span className="icon"><i className="fas fa-file-export is-pulled-right"></i></span>
                </button>
                <div className="auction-list__time-box">
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
        { renderFilterForm() }
        <div className="content container">
          { fixturePayloads.length > 0 ?
            _.map(fixturePayloads, (payload) => {
              const auction = _.get(payload, 'auction');
              const fixtures = _.chain(payload).get('fixtures').uniq().value();
              return (
                <div key={auction.id}>
                    <h2 className="admin-panel__content__header has-margin-top-lg">
                      <AuctionTitle auction={auction} />
                    </h2>
                    <table className="admin-panel__table">
                      <thead>
                        <tr>
                          <th>Fixture ID</th>
                          <th>Vessel</th>
                          <th>Fuel</th>
                          <th>Price</th>
                          <th>Quantity</th>
                          <th>Supplier</th>
                          <th>ETA</th>
                          <th>ETD</th>
                          <th>Delivered</th>
                          <th></th>
                          <th></th>
                        </tr>
                      </thead>
                      <tbody>
                        {
                          _.map(fixtures, (fixture) => {
                            const vessel = _.get(fixture, 'vessel');
                            const fuel = _.get(fixture, 'fuel')
                            const supplier = _.get(fixture, 'supplier');
                            return (
                              <tr key={fixture.id} className={`qa-auction-fixture-${fixture.id}`}>
                                <td className="qa-auction-fixture-auction-name">{fixture.id}</td>
                                <td key={vessel.id} className="qa-auction-fixture-vessel">{vessel.name}</td>
                                <td key={fuel.id} className="qa-auction-fixture-fuel">{fuel.name}</td>
                                <td className="qa-auction-fixture-price">{formatPrice(fixture.price)}</td>
                                <td className="qa-auction-fixture-quantity">{fixture.quantity} M/T</td>
                                <td className="qa-auction-fixture-supplier">{supplier.name}</td>
                                <td className="qa-auction-fixture-eta">{formatUTCDateTime(fixture.eta)}</td>
                                <td className="qa-auction-fixture-etd">{formatUTCDateTime(fixture.etd)}</td>
                                <td>
                                  <CheckBoxField defaultChecked={fixture.delivered} opts={{ readOnly: true }} />
                                </td>
                                <td>
                                  <button className={`button is-small is-primary is-inline-block has-margin-bottom-xs qa-auction-fixture-show_report-${fixture.id}`} onClick={this.handleReportClick.bind(this, fixture)}>{ this.state.displayFixtureReport ? 'Hide Report' : 'Show Report'}</button>
                                </td>
                                <td className="text-right">
                                  <a href={`/auctions/${fixture.auction_id}/fixtures/${fixture.id}/propose_changes`} className={`button is-small is-primary is-inline-block has-margin-bottom-xs qa-auction-fixture-propose_changes-${fixture.id}`}>Propose Changes</a>
                                </td>
                              </tr>
                            );
                          })
                        }
                      </tbody>
                    </table>
                    { this.state.displayFixtureReport && auction.id === this.state.selectedFixtureForReport.auction_id &&
                      <FixtureReportContainer fixture={this.state.selectedFixtureForReport} />
                    }
                </div>
              );
            })
          :
            <section className="admin-panel__content has-margin-top-lg">
              <div className="empty-list">
                <em>No results found</em>
              </div>
            </section>
          }
        </div>
      </div>
    );
  }
}

