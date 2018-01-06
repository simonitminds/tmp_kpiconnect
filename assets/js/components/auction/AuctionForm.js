import React from 'react';
import _ from 'lodash';
import moment from 'moment';
import Datetime from 'react-datetime';
import { Component } from 'react'

class AuctionForm extends React.Component {constructor(props) {
    super(props);
    this.state = {
      selected_port: props.auction.port_id || '',
      selected_vessel: props.auction.vessel_id || '',
      selected_fuel: props.auction.fuel_id || '',
      auction_start: this.setDate(props.auction.auction_start),
      eta: this.setDate(props.auction.eta),
      etd: this.setDate(props.auction.etd),
    };
    this.handlePortChange = this.handlePortChange.bind(this);
    this.handleVesselChange = this.handleVesselChange.bind(this);
    this.handleFuelChange = this.handleFuelChange.bind(this);
  }

  setDate(date) {
    let value = date || moment().hour(0).minute(0)
    return moment(value);
  }

  hour_part(datetime) {
    return moment(datetime).hour();
  }
  handlePortChange(e) {
    this.setState({ selected_port: e.target.value });
  }
  handleVesselChange(e) {
    this.setState({ selected_vessel: e.target.value });
  }
  handleFuelChange(e) {
    this.setState({ selected_fuel: e.target.value });
  }
  handleDateChange(field, date) {
    this.setState({
      [field]: moment(date)
    });
  }
  input_field(model, field, labelText, value, opts) {
    const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
    const labelDisplay = _.has(opts, 'label') ? opts.label : _.capitalize(labelText);
    return (
      <div className="field">
        <label htmlFor={`${model}_${field}`} className={labelClass}>
          {labelDisplay}
        </label>
        <div className="control">
          <input
            type="text"
            name={`${model}[${field}]`}
            id={`${model}_${field}`}
            className="input"
            defaultValue={value}
            autoComplete="off"
          />
        </div>
      </div>
    );
  }

  number_field(model, field, labelText, value, opts) {
    const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
    const labelDisplay = _.has(opts, 'label') ? opts.label : labelText;
    return (
      <div className="field">
        <label htmlFor={`${model}_${field}`} className={labelClass}>
          {labelDisplay}
        </label>
        <div className="control">
          <input
            type="number"
            name={`${model}[${field}]`}
            id={`${model}_${field}`}
            className="input"
            defaultValue={value}
            autoComplete="off"
          />
        </div>
      </div>
    );
  }

  checkbox_field(model, field, labelText, value, opts = {}) {
    const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
    const labelDisplay = _.has(opts, 'label') ? opts.label : _.capitalize(labelText);
    return (
      <div className="field">
        <div className="control">
          <input name={`${model}[${field}]`} type="hidden" value="false" />
          <input
            className="checkbox"
            id={`${model}_${field}`}
            name={`${model}[${field}]`}
            type="checkbox"
            value="true"
          />
          <label htmlFor={`${model}_${field}`} className={labelClass}>
            {labelDisplay}
          </label>
        </div>
      </div>
    );
  }


  render() {
    return (
      <div>
        <input type="hidden" id="auction_auction_start_minute" name="auction[auction_start]" value={this.state.auction_start} />
        <input type="hidden" id="auction_eta_minute" name="auction[eta]" value={this.state.eta} />
        <input type="hidden" id="auction_etd_minute" name="auction[etd]" value={this.state.etd} />

        <div className="field">
          <label htmlFor="auction_vessel_id" className="label">
            Vessel
          </label>
          <div className="control">
            <div className="select is-fullwidth">
              <select
                id="auction_vessel_id"
                name="auction[vessel_id]"
                value={this.state.selected_vessel}
                onChange={this.handleVesselChange}
              >
                <option disabled value="">
                  Please select
                </option>
                {_.map(this.props.vessels, vessel => (
                  <option key={vessel.id} value={vessel.id}>
                    {vessel.name}, {vessel.imo}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        <div className="field">
          <label htmlFor="auction_port_id" className="label">
            Port
          </label>
          <div className="control">
            <div className="select is-fullwidth">
              <select
                id="auction_port_id"
                name="auction[port_id]"
                value={this.state.selected_port}
                onChange={this.handlePortChange}
              >
                <option disabled value="">
                  Please select
                </option>
                {_.map(this.props.ports, port => (
                  <option key={port.id} value={port.id}>
                    {port.name}, {port.country}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        <div className="field">
          <label htmlFor="auction_fuel_id" className="label">
            Fuel
          </label>
          <div className="control">
            <div className="select is-fullwidth">
              <select
                id="auction_fuel_id"
                name="auction[fuel_id]"
                value={this.state.selected_fuel}
                onChange={this.handleFuelChange}
              >
                <option disabled value="">
                  Please select
                </option>
                {_.map(this.props.fuels, fuel => (
                  <option key={fuel.id} value={fuel.id}>
                    {fuel.name}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        {this.number_field('auction', 'fuel_quantity', 'Fuel Quantity (MT)', this.props.auction.fuel_quantity)}
        {this.input_field('auction', 'company', 'company', this.props.auction.company)}
        {this.input_field('auction', 'po', 'po', this.props.auction.po, { labelClass: 'label is-uppercase' })}

        <div className="field is-grouped">
          <label htmlFor="auction_eta" className="label is-uppercase">
            ETA
          </label>
          <div className="control">
            <Datetime
              dateFormat="DD/MM/YYYY"
              inputProps={{
              }}
              timeFormat={false}
              value={this.state.eta}
              onChange={e => this.handleDateChange('eta', e)}
              closeOnSelect={true}
            />
          </div>
          <div className="control">
            <Datetime
              timeFormat={"H:mm"}
              timeConstraints={{minutes: {step: 5}}}
              value={this.state.eta}
              onChange={e => this.handleDateChange('eta', e)}
              dateFormat={false}
              closeOnSelect={true}
            />
          </div>
        </div>

        <div className="field is-grouped">
          <label htmlFor="auction_etd" className="label is-uppercase">
            ETD
          </label>
          <div className="control">
            <Datetime
              dateFormat="DD/MM/YYYY"
              inputProps={{
              }}
              timeFormat={false}
              value={this.state.etd}
              onChange={e => this.handleDateChange('etd', e)}
              closeOnSelect={true}
            />
          </div>
          <div className="control">
            <Datetime
              timeFormat={"H:mm"}
              timeConstraints={{minutes: {step: 5}}}
              value={this.state.etd}
              onChange={e => this.handleDateChange('etd', e)}
              dateFormat={false}
              closeOnSelect={true}
            />
          </div>
        </div>

        <div className="field is-grouped">
          <label htmlFor="auction_start" className="label is-uppercase">
            Auction Start
          </label>
          <div className="control">
            <Datetime
              dateFormat="DD/MM/YYYY"
              inputProps={{
              }}
              timeFormat={false}
              value={this.state.etd}
              onChange={e => this.handleDateChange('auction_start', e)}
              closeOnSelect={true}
            />
          </div>
          <div className="control">
            <Datetime
              timeFormat={"H:mm"}
              timeConstraints={{minutes: {step: 5}}}
              value={this.state.auction_start}
              onChange={e => this.handleDateChange('auction_start', e)}
              dateFormat={false}
              closeOnSelect={true}
            />
          </div>
        </div>

        <div className="field">
          <label htmlFor="auction_duration" className="label">
            Duration
          </label>
          <div className="control">
            <div className="select">
              <select id="auction_duration" name="auction[duration]" defaultValue={this.props.auction.duration}>
                <option disabled value="">
                  Please select
                </option>
                <option value="10">10</option>
                <option value="15">15</option>
                <option value="20">20</option>
              </select>
            </div>
            <span className="select__extra-label">minutes</span>
          </div>
        </div>

        {
          this.checkbox_field(
          'auction',
          'anonymous_bidding',
          'anonymous bidding',
          this.props.auction.anonymous_bidding,
          {
            labelClass: 'label is-capitalized is-inline-block has-margin-left-sm'
          }
        )}
      </div>
    );
  }
}

export default AuctionForm;
