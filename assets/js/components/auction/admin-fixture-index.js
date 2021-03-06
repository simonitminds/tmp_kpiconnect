import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import CheckBoxField from '../check-box-field';
import AuctionTitle from './common/auction-title';
import FixtureDeliveryForm from './fixture-delivery-form';
import FixtureFilterForm from './fixture-filter-form';
import FixtureReportContainer from '../../containers/fixture-report-container';
import { formatUTCDateTime, formatPrice } from '../../utilities';
import { exportCSV, parseCSVFromPayloads } from '../../reporting-utilities';

export default class AdminAuctionFixturesIndex extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
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
      displayDeliveryForm: false,
      selectedFixtureForDelivery: "",
      selectedDeliveryCheckbox: null,
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
      .filter(([_key, value]) => !!value)
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

  createDeliveryFormData(ev) {
    const elements = ev.target.elements;
    const formData = _
      .chain(elements)
      .reject((element) => _.endsWith(element.name, 'date') || element.name === "")
      .reduce((data, element) => {
        data[element.name] = element.value
        return data
      }, {})
      .value();
    return formData;
  }

  handleDeliverySubmit(ev) {
    const fixtureId = this.state.selectedFixtureForDelivery.id;
    const auctionId = this.state.selectedFixtureForDelivery.auction_id;

    const deliveryParams = this.createDeliveryFormData(ev)
    this.props.deliverFixture(ev, fixtureId, auctionId, deliveryParams)
  }

  handleDeliveryClick(fixtureId, ev) {
    const selectedDeliveryCheckbox = this.state.selectedDeliveryCheckbox
    const previouslySelectedFixture = this.state.selectedFixtureForDelivery;
    if (previouslySelectedFixture && !previouslySelectedFixture.delivered) {
      selectedDeliveryCheckbox.checked = false;
    }
    const selectedFixtureForDelivery = _
      .chain(this.props.fixturePayloads)
      .flatMap((payload) => payload.fixtures)
      .find({ 'id': fixtureId })
      .value();

    this.setState({
      selectedFixtureForDelivery,
      displayDeliveryForm: ev.target.checked,
      selectedDeliveryCheckbox: ev.target
    });
  }

  handleReportClick(fixture, ev) {
    ev.preventDefault();
    if (this.state.displayFixtureReport) {
      this.setState({
        selectedFixtureForReport: null,
        displayFixtureReport: false,
      })

      ev.target.innerText = 'Show Report';
    } else {
      this.setState({
        selectedFixtureForReport: fixture,
        displayFixtureReport: true,
      })

      ev.target.innerText = 'Hide Report'
    }
  }

  render() {
    const fixturePayloads = this.state.fixturePayloads;

    return(
      <section className="admin-panel__content is-three-quarters">
        <h2 className="admin-panel__content__header">
          <span className="is-4 is-inline-block">Auction Fixtures</span>
          <button className="button is-link is-primary has-margin-left-auto" onClick={this.handleExportClick.bind(this)}>
            <span>Export Benchmarking Reports</span>
            <span className="icon"><i className="fas fa-file-export is-pulled-right"></i></span>
          </button>
        </h2>
        <FixtureFilterForm
          clearFilter={this.clearFilter.bind(this)}
          filterPayloads={this.filterPayloads.bind(this)}
          fixturePayloads={this.props.fixturePayloads}
          handleTimeRange={this.handleTimeRange.bind(this)}
          startTimeRange={this.state.filterParams.startTimeRange}
          endTimeRange={this.state.filterParams.endTimeRange}
        />
        { fixturePayloads.length > 0 ?
          _.map(fixturePayloads, (payload) => {
            const auction = _.get(payload, 'auction');
            const fixtures = _.chain(payload).get('fixtures').uniq().value();
            return (
              <div key={auction.id}>
                <section className="admin-panel__content">
                  <h2 className="admin-panel__content__header has-margin-top-lg">
                    <AuctionTitle auction={auction} />
                    <a href={`/admin/auctions/${auction.id}/fixtures/new`} className="button is-link is-inline-block has-margin-left-auto">
                      <i className="fas fa-plus is-inline-block has-margin-right-sm"></i>
                      Add Fixture
                    </a>
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
                          const delivered = _.get(fixture, 'delivered', false);
                          const vessel = delivered ? _.get(fixture, 'delivered_vessel.name', '???') : _.get(fixture, 'vessel.name', "???");
                          const fuel = delivered ? _.get(fixture, 'delivered_fuel.name', '???') : _.get(fixture, 'fuel.name', "???");
                          let quantity = delivered ? _.get(fixture, 'delivered_quantity', "???") : _.get(fixture, 'quantity', '???');
                          quantity = quantity == "???" ? quantity : `${quantity} M/T`;
                          let price = delivered ? _.get(fixture, 'delivered_price', '???') : _.get(fixture, 'price', "???");
                          price = price == "???" ? price : formatPrice(price);
                          const supplier = delivered ? _.get(fixture, 'delivered_supplier.name', '???') : _.get(fixture, 'supplier.name', "???");
                          let eta = delivered ? _.get(fixture, 'delivered_eta', '???') : _.get(fixture, 'eta', "???");
                          eta = eta == "???" ? eta : formatUTCDateTime(eta);
                          let etd = delivered ? _.get(fixture, 'delivered_etd', '???') : _.get(fixture, 'etd', "???");
                          etd = etd == "???" ? etd : formatUTCDateTime(etd);
                          return (
                            <React.Fragment>
                              <tr key={fixture.id} className={`qa-auction-fixture-${fixture.id}`}>
                                <td className="qa-auction-fixture-auction-name">{fixture.id}</td>
                                <td className="qa-auction-fixture-vessel">{vessel}</td>
                                <td className="qa-auction-fixture-fuel">{fuel}</td>
                                <td className="qa-auction-fixture-price">{price}</td>
                                <td className="qa-auction-fixture-quantity">{quantity}</td>
                                <td className="qa-auction-fixture-supplier">{supplier}</td>
                                <td className="qa-auction-fixture-eta">{eta}</td>
                                <td className="qa-auction-fixture-etd">{etd}</td>
                                <td>
                                  <CheckBoxField
                                    model={`fixture-${fixture.id}`}
                                    field={'delivered'}
                                    defaultChecked={delivered}
                                    onChange={this.handleDeliveryClick.bind(this, fixture.id)}
                                    opts={{ readOnly: delivered }}
                                  />
                                </td>
                                <td>
                                  <button className={`button is-small is-primary is-inline-block has-margin-bottom-xs qa-auction-fixture-show_report-${fixture.id}`} onClick={this.handleReportClick.bind(this, fixture)}>Show Report</button>
                                </td>
                                <td className="text-right">
                                  <a href={`/admin/auctions/${fixture.auction_id}/fixtures/${fixture.id}/edit`} className={`button is-small is-primary is-inline-block has-margin-bottom-xs qa-auction-fixture-edit-${fixture.id}`}>Edit</a>
                                </td>
                              </tr>
                            </React.Fragment>
                          );
                        })
                      }
                    </tbody>
                  </table>
                  { this.state.displayDeliveryForm && auction.id === this.state.selectedFixtureForDelivery.auction_id &&
                    <FixtureDeliveryForm fixture={this.state.selectedFixtureForDelivery} fixturePayloads={this.props.fixturePayloads} handleDeliverySubmit={this.handleDeliverySubmit.bind(this)} />
                  }
                  { this.state.displayFixtureReport && auction.id === this.state.selectedFixtureForReport.auction_id &&
                    <FixtureReportContainer fixture={this.state.selectedFixtureForReport} />
                  }
                </section>
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
      </section>
    );
  }
}
